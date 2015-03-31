source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.8'
gem 'mysql2', '~> 0.3.18'

# Assets
gem 'sass-rails',   '~> 4.0.3'
gem 'bootstrap-sass'
gem 'bootstrap-filestyle-rails'
gem 'uglifier',     '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'therubyracer', '~> 0.12.1', platforms: :ruby

gem 'haml-rails'

gem 'paperclip', '~> 4.2'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring',        group: :development

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
gem 'unicorn'

# Use debugger
# gem 'debugger', group: [:development, :test]

group :development, :test do
  gem 'rspec-rails', '~> 3.1'
  gem 'pry-rails'
end

group :development do
  gem 'guard'
  gem 'guard-rspec'

  gem 'capistrano-rbenv',    '~> 2.0',   require: false
  gem 'capistrano-rails',    '~> 1.1',   require: false
  gem 'capistrano-bundler',  '~> 1.1',   require: false
  gem 'capistrano3-unicorn', '~> 0.2',   require: false

  gem 'better_errors'
  gem 'binding_of_caller'
end

group :test do
  gem 'factory_girl_rails', '~> 4.5'
  gem 'shoulda-matchers', require: false
end

# Application Gems.
gem 'rest-client'
gem 'virtus'
gem 'turbine-graph', require: 'turbine'
gem 'quintel_merit', github: 'quintel/merit', branch: 'arbitrary-length'
