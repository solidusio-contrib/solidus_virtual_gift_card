source 'https://rubygems.org'

gem 'spree', github: 'spree/spree', tag: 'v2.2.2'
# Provides basic authentication functionality for testing parts of your engine
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: '2-2-stable'

gemspec

group :test do
  gem 'with_model'
end

group :test, :development do
  gem 'pry-byebug'
end
