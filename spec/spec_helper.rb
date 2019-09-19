# frozen_string_literal: true

require "simplecov"
SimpleCov.start "rails"

ENV["RAILS_ENV"] ||= "test"

require File.expand_path('dummy/config/environment.rb', __dir__)

require "solidus_support"
require "solidus_support/extension/feature_helper"
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/capybara_ext'
require 'webdrivers'

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

require 'spree_virtual_gift_card/factories'

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.raise_errors_for_deprecations!

  config.example_status_persistence_file_path = "./spec/examples.txt"

  config.include Spree::TestingSupport::UrlHelpers
  config.include Spree::TestingSupport::ControllerRequests, type: :controller
end
