source "https://rubygems.org"

branch = ENV.fetch("SOLIDUS_BRANCH", "master")
gem "solidus", github: "solidusio/solidus", branch: branch
gem "solidus_auth_devise"

if ENV["DB"] == "mysql"
  gem "mysql2", "~> 0.4.10"
else
  gem "pg", "~> 0.21"
end

group :test do
  if branch == "master" || branch >= "v2.0"
    gem "rails-controller-testing"
  else
    gem "rails_test_params_backport"
  end

  if branch < "v2.5"
    gem "factory_bot", "4.10.0"
  else
    gem "factory_bot", "> 4.10.0"
  end
end

group :development, :test do
  gem "pry-rails"
end

gemspec
