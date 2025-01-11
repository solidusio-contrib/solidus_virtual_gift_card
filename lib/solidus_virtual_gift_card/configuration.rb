# frozen_string_literal: true

module SolidusVirtualGiftCard
  class Configuration
    attr_accessor :send_gift_card_emails

    def initialize(send_gift_card_emails: true)
      @send_gift_card_emails = send_gift_card_emails
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
