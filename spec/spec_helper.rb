# Run Coverage report
require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Models', 'app/models'
  add_group 'Views', 'app/views'
  add_group 'Libraries', 'lib'
end

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)

require 'rspec/rails'
require 'rake'

require 'database_cleaner'
require 'ffaker'

require 'spree/testing_support/factories'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/url_helpers'

require 'cancan/matchers'

require "spree_virtual_gift_card/factories"

require "capybara/poltergeist"
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, timeout: 120)
end
Capybara.javascript_driver = :poltergeist

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.mock_with :rspec

  config.color = true
  config.order = "random"

  config.expose_current_running_example_as :example
  config.fail_fast = ENV["FAIL_FAST"] || false

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.use_transactional_fixtures = false

  config.example_status_persistence_file_path = "./spec/examples.txt"

  config.include FactoryGirl::Syntax::Methods
  config.include Spree::TestingSupport::ControllerRequests, type: :controller
  config.include Spree::TestingSupport::UrlHelpers, type: :controller

  config.before :suite do
    DatabaseCleaner.clean_with :truncation
  end

  config.before :each do |example|
    if RSpec.current_example.metadata[:js]
      page.driver.browser.url_blacklist = ['http://fonts.googleapis.com']
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
    end
    DatabaseCleaner.start

    Spree::Api::Config[:requires_authentication] = true
    Spree::Config.reset
  end

  # After each spec clean the database.
  config.append_after :each do
    DatabaseCleaner.clean
  end

  if defined?(VersionCake::TestHelpers)
    config.include VersionCake::TestHelpers, type: :controller
    config.before(:each, type: :controller) do
      set_request_version('', 1)
    end
  end
end
