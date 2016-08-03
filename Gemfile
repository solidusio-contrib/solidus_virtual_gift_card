source "https://rubygems.org"

branch = ENV.fetch('SOLIDUS_BRANCH', 'master')
gem "solidus", github: "solidusio/solidus", branch: branch
gem "solidus_auth_devise"

gem 'pg'
gem 'mysql2'

group :test, :development do
  gem 'pry-rails'
end

gemspec
