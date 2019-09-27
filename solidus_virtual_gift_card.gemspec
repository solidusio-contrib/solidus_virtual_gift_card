# encoding: UTF-8

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'solidus_virtual_gift_card'
  s.version     = '1.3.0'
  s.summary     = "Virtual gift card for purchase, drops into the user's account as store credit"
  s.required_ruby_version = ">= 2.2.2"

  s.author    = 'Solidus Team'
  s.email     = 'contact@solidus.io'
  s.homepage  = 'https://solidus.io'
  s.license   = 'BSD-3-Clause'

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency "solidus", [">= 1.2", "< 3"]
  s.add_dependency 'deface'

  s.add_development_dependency 'rspec-rails', '~> 4.0.0.beta2'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'factory_bot'
  s.add_development_dependency 'capybara', '~> 3.29'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'solidus_support'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'webdrivers'
  s.add_development_dependency 'ffaker'
end
