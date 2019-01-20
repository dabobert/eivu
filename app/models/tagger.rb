module Tagger


  class Test
    def self.run
      # cloud_file = Bucket.last.cloud_files.last
      # cloud_file.path_to_file = "/Users/jinx/Dropbox/eivu/sample/Sound Effects/Cow-SoundBible.com-868293659.mp3"
      # Tagger::Factory.generate(cloud_file).identify!
# path = "/Users/jinx/Music/iTunes/iTunes\ Media/Music/Compilations/Essential\ Mix/11.08.2008\ \(256kbit\).m4a"
 # path = "/Users/jinx/Music/iTunes/iTunes\ Media/Music/White\ Label/Alicia/01\ Alicia.mp3"
      cf = CloudFile.find(1978)
      cf.path_to_file = "/Users/jinx/Desktop/sample/Justin\ Timberlake/Suit\ \&\ Tie\ \(Feat\ JAY\ Z\)\ -\ Single/01\ Suit\ \&\ Tie.mp3"
      # Tagger::Factory.generate("/Users/jinx/Dropbox/eivu/sample/Mala/Alicia/01\ Alicia.mp3").identify!
      Tagger::Factory.generate(cf).identify_and_update!
    end
  end

  class Factory
    def self.generate(input)
      if input.is_a? String
        path_to_file = input
      elsif input.is_a? CloudFile
        cloud_file = input
        path_to_file = input.path_to_file
      end

      extension = File.extname(path_to_file)
      file      = File.open(path_to_file)
      if extension.present?
        mime    = MimeMagic.by_extension(".m4a")
      else
        mime    = MimeMagic.by_magic(file)
      end

      klass     = Kernel.const_get("Tagger::#{mime.mediatype.titlecase}")
      klass.new(input, mime, file)
    end
  end


  class Base

    class << self
      def set_flags_via_path(path_to_file)
        if path_to_file.present? && (path_to_file.include?("/pronz") || path_to_file.include?("/peepshow"))
          {
            :peepy => true,
            :nsfw => true
          }
        else
          {}
        end
      end

      def parse_artist_string(value)
        return [] if value.blank?
        value.split("&").collect do |name|
          {:name => name.strip, :primary => true }
        end
      end
    
      def convert_primary_to_value(input)
        if input
          1
        else
          2
        end
      end
    end



    def initialize(input, mime, file)
      if input.is_a? String
        @path_to_file = input
      elsif input.is_a? CloudFile
        @cloud_file   = input
        @path_to_file = input.path_to_file
      end

      @mime       = mime
      @file       = file
      @attributes = {}
    end


    def save_data!
      return if @cloud_file.blank?

      if @release_attrs.compact.present?
        @release = Release.configure_and_save!(@release_attrs)
        @release_artists.each do |raw_artist|
          artist = Artist.configure_and_save! :name => raw_artist.name, :ext_id => raw_artist.ext_id, :data_source_id => @release.data_source_id
          ArtistRelease.find_or_create_by! :artist_id => artist.id, :release_id => @release.id, :relationship_id => Tagger::Base.convert_primary_to_value(raw_artist.primary)
        end

        @track_artists.each do |raw_artist|
          artist = Artist.configure_and_save! :name => raw_artist.name, :ext_id => raw_artist.ext_id, :data_source_id => @release.data_source_id
          ArtistCloudFile.find_or_create_by! :artist_id => artist.id, :cloud_file_id => @cloud_file.id, :relationship_id => Tagger::Base.convert_primary_to_value(raw_artist.primary)
        end

        @cloud_file.update_attributes(@cloud_file_attrs.merge(:release_id => @release.id))
      end
      
      @metadata.each do |key, value|
        label   = key.to_s.gsub("_", " ").titlecase
        type    = MetadataType.find_or_create_by!(:value => label)
        datum   = Metadatum.find_or_create_by!(:value => value, :user_id => @cloud_file.user_id, :metadata_type_id => type.id)
        Metatagging.find_or_create_by!(:metadatum_id => datum.id, :cloud_file_id => @cloud_file.id)
      end

      # Uploads release artwork
      if @artwork_data.present?
        temp_artwork = Tempfile.new(SecureRandom.uuid)
        temp_artwork.binmode
        temp_artwork.write(@artwork_data)
        CloudFileTaggerUploader.perform(temp_artwork.path, bucket, :folder_id => cloud_file.folder_id, :release_id => cloud_file.release_id)
      end
    end
  end


  class Audio < Base
    def identify_and_update!
      identify
      save_data!
    end


    def identify
      @id3_attr       = Hashie::Mash.new
      @fp_attr = {}
      ################
      #
      # Get Info via ID3
      id3_info        = ID3Tag.read(@file)
      
      if id3_info.artist.present?
        id3_artist = [{:name => id3_info.artist, :primary => true}]
      else
        id3_artist = []
      end

      @id3_attr[:_source]   = id3_info.get_frame(:PRIV).try(:owner_identifier) #"www.amazon.com"
      @id3_attr[:artists]   = Tagger::Audio.parse_artist_string(id3_info.artist) #id3_artist
      @id3_attr[:title]     = id3_info.title
      @id3_attr[:release]   = id3_info.album
      @id3_attr[:year]      = id3_info.year
      @id3_attr[:track_num] = id3_info.track_nr
      @id3_attr[:genre]     = id3_info.genre
      @id3_attr[:comments]  = id3_info.comments.try(:strip)
      @artwork_data         = id3_info.get_frame(:APIC).try(:content)


      ################
      #
      # Get Info via AcouticFingerprint Service
      fingerprint     = Fingerprinter.new(@path_to_file)
      fingerprint.submit if fingerprint.cleansed_fingerprint.present?

      @flags_via_path = Tagger::Audio.set_flags_via_path(@path_to_file)


      if @id3_attr[:_source].present?
        track_name   = @id3_attr[:title]
        release_name = @id3_attr[:release]
      else
        track_name   = fingerprint.track.try(:title) || @id3_attr.title
        release_name = fingerprint.release.try(:title) || @id3_attr.release
      end

      track_id     = fingerprint.track.try(:ext_id)
      release_id   = fingerprint.release.try(:ext_id) 
      @release_artists = fingerprint.try(:release).try(:artists) || @id3_attr[:artists]
      @track_artists   = fingerprint.try(:track).try(:artists) || @id3_attr[:artists]

      # creates hash to release metadata, nil values will be rmeoved.
      # is used by save_data fn
      # only created if we have valid release information
      if release_name || release_id
        @release_attrs = {
          :name => release_name,
          :ext_id => release_id,
          :data_source_id => 1
        }.merge(@flags_via_path).compact
      else
        @release_attrs = {}
      end

      # creates hash to store cloud file data, nil values will be rmeoved.
      # is used by save_data fn
      @cloud_file_attrs = {
        :name => track_name,
        :ext_id => track_id,
        :data_source_id => (track_id.present? ? 1 : nil),
        :release_pos => @id3_attr[:track_num],
        :year => @id3_attr[:year],
        :duration => fingerprint.try(:duration)
      }.merge(@flags_via_path).compact

      # creates hash to store metadata, nil values will be rmeoved.
      # is used by save_data fn
      @metadata = Hashie::Mash.new({
        :genre => @id3_attr[:genre],
        :comments => @id3_attr[:comments],
        :acoustid_fingerprint => fingerprint.try(:cleansed_fingerprint),
        :original_subpath => Folder.subpath(path_to_file),
        :original_fullpath => path_to_file,
      }).compact
    end
  end


  class Video < Base
    def determine_rating(path_to_file)
      if Pathname.new(path_to_file).basename.to_s.starts_with?("_")
        5
      elsif Pathname.new(path_to_file).basename.to_s.starts_with?("`")
        4.5
      end
    end
  end


end
