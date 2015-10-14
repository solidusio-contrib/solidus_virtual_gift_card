Rails.application.config.to_prepare do
  Spree::Api::LineItemsController.line_item_options += [:gift_card_details]
end
