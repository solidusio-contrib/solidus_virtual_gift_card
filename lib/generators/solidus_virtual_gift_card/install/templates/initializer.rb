# frozen_string_literal: true

SolidusVirtualGiftCard.configure do |config|
  # Enable or disable sending gift card email notifications
  # Set to `true` to allow emails to be sent, or `false` to disable them
  config.send_gift_card_emails = true
  config.credit_to_new_gift_card = false
end
