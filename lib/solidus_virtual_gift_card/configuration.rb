# frozen_string_literal: true

require 'spree/preferences/configuration'
require 'active_support/all'

module SolidusVirtualGiftCard
  class Configuration < Spree::Preferences::Configuration
    preference :send_gift_card_emails, :string, default: ''
    preference :credit_to_new_gift_card, :boolean, default: true
  end
end
