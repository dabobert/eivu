source 'https://rubygems.org'
ruby '2.5.1'

# i/o
gem 'rails', '5.2.2'
gem "random_data", "~> 1.6.0" #allows to easily create random date, like Random.email or Random.last
gem 'pg', '~> 0.18' #postgres
gem 'ancestry' #used to nest project_products by providing a parent_id and many convenience methods
gem 'aws-sdk', '~> 2.0.41'
gem 'mime-types', '~> 3.2.2'
gem 'devise', '~> 4.7' #user authentication
gem 'mimemagic', '~> 0.3.0' #determine mime type by magic
gem 'mini_magick', '4.9.4' #there's an issues with v3.7 https://github.com/carrierwaveuploader/carrierwave/issues/1282
gem 'rest-client'#, '~> 1.8.0' #A simple HTTP and REST client for Ruby, inspired by the Sinatra microframework style of specifying actions
gem 'attr_encrypted', '~> 3.1' #Generates attr_accessors that encrypt and decrypt attributes transparently
gem 'has_secure_token' #generate the 24-character unique token
gem 'bitfields', '~> 0.6.0' #store multiple booleans in a single integer
gem 'foreman', '~> 0.82.0' #Manage Procfile-based applications http://ddollar.github.com/foreman
# gem "rjson"  #templating for json (no version in gem because it doenst have any depenedencies)
gem 'webpacker', '>= 4.0.x' #Use Webpack to manage app-like JavaScript modules in Rails
gem 'id3tag', '~> 0.11.0' #mp3 id3 tagger
# gem 'resque', '~> 1.25', '>= 1.25.2'
gem 'rack-cors'
gem "oj" #faster json parsing
gem 'andyw8-itunes-library', '~> 0.1.3'
gem 'itunes_parser', '~> 1.1', '>= 1.1.3' #A fast and simple iTunes XML parser based on nokogiri-plist
gem "fuzzy_match" #Find a needle (a document or record) in a haystack using string similarity and (optionally) regular expression rules. Uses Dice's Coefficient (aka Pair Similiarity) and Levenshtein Distance internally.
gem 'hashie', '~> 3.6' # collection of classes and mixins that make hashes more powerful.
gem 'uglifier', '>= 1.3.0' # has to be outside of assets, to its present at boot. Use Uglifier as compressor for JavaScript assets
gem 'sidekiq', '~> 4.1', '>= 4.1.2' #Simple, efficient background processing for Ruby.
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Backgound Processing
gem 'activejob-traffic_control', '~> 0.1.3' #Traffic control for ActiveJob: Concurrency/enabling/throttling

# presentation
gem 'jquery-rails' # Use jquery as the JavaScript library
# gem 'turbolinks' # Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'sass-rails', '~> 5.0.7' # Use SCSS for stylesheets and useful for Sass-powered version of Bootstrap
gem 'bootstrap-sass', '~> 3.4.1' #twitter bootstrap stylings
# gem 'coffee-rails', '~> 4.1.0'
gem 'jb', '~> 0.4.1' #Faster and simpler Jbuilder alternative
gem 'graphql', '~> 1.9', '>= 1.9.16'
# bundle exec rake doc:rails generates the API under doc/api.

group :doc do 
  gem 'sdoc', '~> 0.4.0'
end

group :production do
  gem 'rails_12factor'
end

gem 'puma', "5.3.1"

group :development, :test, :cucumber do
  # gem 'spring' # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "better_errors" 
  gem 'binding_of_caller' #irb on better-errors error pages
  gem 'rb-readline'
  gem 'pry'
  gem 'pry-byebug' #replaces pry-debugger becasuse pry-debugger doesnt work with ruby 2
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
# # Use SCSS for stylesheets
  gem 'coffee-rails'

#   # See https://github.com/sstephenson/execjs#readme for more supported runtimes
#   # gem 'therubyracer', :platforms => :ruby
#   # Use Uglifier as compressor for JavaScript assets

end

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]


gem 'graphiql-rails', group: :development
gem 'active_model_otp'
gem 'rqrcode'