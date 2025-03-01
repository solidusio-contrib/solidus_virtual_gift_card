# frozen_string_literal: true

require 'spree/preferences/configuration'
require 'active_support/all'

module SolidusVirtualGiftCard
  class Configuration < Spree::Preferences::Configuration
    preference :send_gift_card_emails, :string, default: ''
    preference :credit_to_new_gift_card, :boolean, default: true

    preference :authorize_timeout, :time, default: 1.month
    class_name_attribute :schedule_job_class, default: 'SolidusVirtualGiftCard::VoidExpiredAuthorizedEventsJob'
  end
end
