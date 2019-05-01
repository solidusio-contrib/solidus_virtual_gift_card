# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "spree_virtual_gift_card/version"

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = "solidus_virtual_gift_card"
  s.version     = SpreeVirtualGiftCard::VERSION
  s.summary     = "Virtual gift card for purchase, drops into the user\'s account as store credit"
  s.description = s.summary
  s.license     = "BSD-3-Clause"

  s.author    = "Solidus Team"
  s.email     = "contact@solidus.io"
  s.homepage  = "https://solidus.io"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.required_ruby_version = ">= 2.2.2"

  s.add_dependency "solidus", [">= 2.0", "< 3"]
  s.add_dependency "solidus_support"
  s.add_dependency "deface", "~> 1.0"

  s.add_development_dependency "capybara"
  s.add_development_dependency "capybara-screenshot"
  s.add_development_dependency "coffee-rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "factory_bot"
  s.add_development_dependency "ffaker"
  s.add_development_dependency "poltergeist"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "rubocop", "~> 0.53.0"
  s.add_development_dependency "rubocop-rspec"
  s.add_development_dependency "sass-rails"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "puma"
  s.add_development_dependency "sqlite3", "~> 1.3.6"
end
