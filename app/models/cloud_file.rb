class CloudFile < ActiveRecord::Base

  belongs_to :folder
  belongs_to :bucket, :inverse_of => :cloud_file
  has_one :user, :through => :bucket
  has_many :metataggings, :dependent => :destroy
  has_many :metadata, :through => :metataggings, :dependent => :destroy
  has_many :taggings, :source => :cloud_file_tagging, :dependent => :destroy
  has_many :cloud_file_taggings, :dependent => :destroy
  has_many :tags, :through => :cloud_file_taggings

  accepts_nested_attributes_for :metataggings

  validates_uniqueness_of :md5, :scope => :bucket_id
  validates_presence_of :bucket_id

  attr_accessor :relative_path

  before_save :parse_relative_path
  after_destroy :delete_remote


  default_scope { includes(:bucket => :region) }

  def visit
    system "open #{self.url}"
  end

  class << self

    def online?(uri)
      url = URI.parse(uri)
      req = Net::HTTP.new(url.host, url.port)
      req.request_head(url.path).code == "200"
    end

    def upload!(path_to_file, bucket, options={})
      CloudFile.upload path_to_file, bucket, options.merge(:prune => true)
    end

    def upload(path_to_file, bucket, options={})
      ActiveRecord::Base.transaction do
        #fetch bucket
        bucket    = Bucket.determine(bucket)

        #get metadata
        md5       = Digest::MD5.file(path_to_file).hexdigest.upcase
        file      = File.open(path_to_file)
        mime      = MimeMagic.by_magic(File.open(path_to_file))
        store_dir = md5.scan(/.{2}|.+/).join("/")
        filename  = File.basename(path_to_file)
        sanitized_filename = CloudFile.sanitize(filename)

        #test if file already exists
        old_id = CloudFile.where(:md5 => md5, :bucket_id => bucket.id).first.try(:id)
        raise "File already exists (id: #{old_id})" if old_id.present?

        #upload file and create cloud file object
        obj = bucket.create_object("#{store_dir}/#{sanitized_filename}")
        obj.upload_file(path_to_file, :acl => 'public-read', :content_type => mime.type, :metadata => {})
        cloud_file = CloudFile.create! :bucket_id => bucket.id, :folder => Folder.create_from_path(path_to_file), :md5 => md5, :rating => CloudFile.determine_rating(path_to_file), :filesize => file.size, :name => filename, :content_type => mime.type, :asset => sanitized_filename
        
        #remove file if prune is true
        if options[:prune] == true
          if CloudFile.online?(cloud_file.url)
            FileUtils.rm(path_to_file) 
          else
            raise "file not online"
          end
        end

        #clear cached files immediately
        cloud_file
      end
    end


    def determine_rating(path_to_file)
      if Pathname.new(path_to_file).basename.to_s.starts_with?("_")
        5
      elsif Pathname.new(path_to_file).basename.to_s.starts_with?("`")
        4.5
      end
    end

    def sanitize(name)
      name = name.tr("\\", "/") # work-around for IE
      name = File.basename(name)
      name = name.gsub(/[^a-zA-Z0-9\.\-\+_]/, "_")
      name = "_#{name}" if name =~ /\A\.+\z/
      name = "unnamed" if name.size == 0
      return name.mb_chars.to_s
    end
  end


  def smart_name
    self.name || self.asset
  end

  def url
    raise "Region Not Defined for bucket: #{self.bucket.name}" if self.bucket.region_id.blank?
    @url ||= "http://#{self.bucket.name}.#{self.bucket.region.endpoint}/#{md5.scan(/.{2}|.+/).join("/")}/#{self.asset}"
  end

  def filename
    self.asset
  end

  def path
    @path ||= "#{self.md5.scan(/.{2}|.+/).join("/")}/#{self.filename}"
  end

  def delete_remote
    self.user.s3_client.delete_object(
      # required
      :bucket => self.bucket.name,
      # required
      :key => self.path
    )
  end

  def tag_list=(tag_array)
    tag_array.each do |value|
      tag = Tag.find_or_create_by! :value => value, :user_id => self.user.id
      self.cloud_file_taggings.find_or_initialize_by! :tag_id => tag.id
    end

    binding.pry
  end

  def metadata_list=(info)
    binding.pry    
  end


  # def progress
  #   file = File.open(filepath, 'r', encoding: 'BINARY')
  #   file_to_upload = "#{s3_dir}/#{filename}"
  #   upload_progress = 0

  #   opts = {
  #     content_type: mime_type,
  #     cache_control: 'max-age=31536000',
  #     estimated_content_length: file.size,
  #   }

  #   part_size = self.compute_part_size(opts)

  #   parts_number = (file.size.to_f / part_size).ceil.to_i
  #   obj          = s3.objects[file_to_upload]

  #   begin
  #       obj.multipart_upload(opts) do |upload|
  #         until file.eof? do
  #           break if (abort_upload = upload.aborted?)

  #           upload.add_part(file.read(part_size))
  #           upload_progress += 1.0/parts_number

  #           # Yields the Float progress and the String filepath from the
  #           # current file that's being uploaded
  #           yield(upload_progress, upload) if block_given?
  #         end
  #       end
  #   end
  # end
  ############################################################################
  private
  ############################################################################

  #relative path is used to construct the folder tree
  def parse_relative_path
    if self.relative_path.blank?
      self.folder_id = nil
    else
      @manual_ancestry= []
      #convert the file path into an array
      folder_array = self.relative_path.split("/").reject { |x| x.empty? }
      #remove the last element because it will always be the last element
      folder_array.pop
      folder_array.each do |sub_dir|
        if @manual_ancestry.present?
          ancestry_str = @manual_ancestry.join("/")
        else
          ancestry_str = nil
        end
        folder = Folder.find_or_create_by! :ancestry => ancestry_str, :bucket_id => self.bucket.id, :name => sub_dir
        @manual_ancestry << folder.id
      end
      self.folder_id = @manual_ancestry.last
    end
  end
end
