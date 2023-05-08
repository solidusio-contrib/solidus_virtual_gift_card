# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)
require 'solidus_virtual_gift_card/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'solidus_virtual_gift_card'
  s.version     = SolidusVirtualGiftCard::VERSION
  s.summary     = "Virtual gift card for purchase, drops into the user's account as store credit"
  s.description = s.summary

  s.required_ruby_version = '>= 2.4.0'

  s.author   = 'Solidus Team'
  s.email    = 'contact@solidus.io'
  s.homepage = 'https://github.com/solidusio-contrib/solidus_virtual_gift_card'
  s.license  = 'BSD-3-Clause'

  s.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  s.test_files = Dir['spec/**/*']
  s.bindir = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  if s.respond_to?(:metadata)
    s.metadata["homepage_uri"] = s.homepage if s.homepage
    s.metadata["source_code_uri"] = s.homepage if s.homepage
  end

  s.add_dependency 'deface'
  s.add_dependency 'coffee-rails'
  s.add_dependency 'solidus_core', '>= 2.0.0', '< 5'
  s.add_dependency 'solidus_support', '~> 0.5'

  s.add_development_dependency 'solidus_dev_support'
end
