# frozen_string_literal: true

module SolidusVirtualGiftCard
  class Configuration
    attr_accessor :send_gift_card_emails, :credit_to_new_gift_card

    def initialize(send_gift_card_emails: true, credit_to_new_allocation: false)
      @send_gift_card_emails = send_gift_card_emails
      @credit_to_new_allocation = credit_to_new_allocation
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
