source 'https://rubygems.org'

gem 'spree', github: 'bonobos/spree', branch: '2-2-dev'
# Provides basic authentication functionality for testing parts of your engine
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: '2-2-stable'

gemspec

group :test do
  gem 'with_model'
end

group :test, :development do
  gem 'pry-byebug'
end
