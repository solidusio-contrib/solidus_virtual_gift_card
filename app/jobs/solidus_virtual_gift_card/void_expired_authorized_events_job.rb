# frozen_string_literal: true

module SolidusVirtualGiftCard
  class VoidExpiredAuthorizedEventsJob < ApplicationJob
    queue_as :default

    def perform
      # Subquery to get the latest 'created_at' timestamp for each virtual_gift_card_event_id
      subquery = ::Spree::VirtualGiftCardEvent
                 .group(:virtual_gift_card_id)
                 .where('spree_virtual_gift_card_events.created_at < ?', Time.current - ::SolidusVirtualGiftCard::Config.authorize_timeout)
                 .select('virtual_gift_card_id, MAX(created_at) AS max_created_at')

      # Main query:
      # 1. Joins the subquery to get the latest event for each virtual_gift_card_id
      # 2. Filters events where the 'created_at' is older than the configured 'authorize_timeout'
      # 3. Filters events where the action is 'authorize', meaning it’s an authorized event
      ::Spree::VirtualGiftCardEvent
        .joins("INNER JOIN (#{subquery.to_sql}) AS subquery ON spree_virtual_gift_card_events.virtual_gift_card_id = subquery.virtual_gift_card_id")
        .where('spree_virtual_gift_card_events.created_at = subquery.max_created_at')
        .where(action: 'authorize')
        .find_each do |event|
          payment = ::Spree::Payment.find_by(source: event.virtual_gift_card)

          Rails.logger.error("Payment not found for event #{event.authorization_code}") && next if payment.nil?

          payment_source = payment.source

          # Void the payment
          payment_source.void(event.authorization_code)
        end
    end
  end
end
