# frozen_string_literal: true

require_relative 'lib/solidus_virtual_gift_card/version'

Gem::Specification.new do |spec|
  spec.name = 'solidus_virtual_gift_card'
  spec.version = SolidusVirtualGiftCard::VERSION
  spec.authors = ['Solidus Team']
  spec.email = 'contact@solidus.io'

  spec.summary = "Virtual gift card for purchase, drops into the user's account as store credit"
  spec.description = "Virtual gift card for purchase, drops into the user's account as store credit"
  spec.homepage = 'https://github.com/solidusio-contrib/solidus_virtual_gift_card'
  spec.license = 'BSD-3-Clause'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/solidusio-contrib/solidus_virtual_gift_card'
  spec.metadata['changelog_uri'] = 'https://github.com/DanielePalombo/solidus_virtual_gift_card/blob/main/CHANGELOG.md'

  spec.required_ruby_version = Gem::Requirement.new('>= 3.1', '< 4')

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  files = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }

  spec.files = files.grep_v(%r{^(test|spec|features)/})
  spec.test_files = files.grep(%r{^(test|spec|features)/})
  spec.bindir = "exe"
  spec.executables = files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'coffee-rails'
  spec.add_dependency 'deface'
  spec.add_dependency 'solidus_core', ['>= 2.0.0', '< 5']
  spec.add_dependency 'solidus_support', '~> 0.5'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'solidus_dev_support', '~> 2.10'
end
