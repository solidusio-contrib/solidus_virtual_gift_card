# frozen_string_literal: true

module LineItemDecorator
  extend ActiveSupport::Concern

  included do
    prepend(InstanceMethods)
  end

  module InstanceMethods
    private

    def permitted_line_item_attributes
      super + [gift_card_details: [:recipient_name, :recipient_email, :gift_message, :purchaser_name, :send_email_at]]
    end
  end
end

Spree::Api::LineItemsController.include LineItemDecorator
