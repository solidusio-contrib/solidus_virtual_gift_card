# frozen_string_literal: true

Rails.application.config.to_prepare do
  Spree::PermittedAttributes.line_item_attributes << { options: [gift_card_details: [:recipient_name, :recipient_email, :gift_message, :purchaser_name, :send_email_at]] }
  if Spree::Config.respond_to?(:line_item_comparison_hooks)
    Spree::Config.line_item_comparison_hooks << 'gift_card_match'
  else
    Spree::Order.line_item_comparison_hooks.add('gift_card_match')
  end
end
