# frozen_string_literal: true

module Spree
  class PaymentMethod::GiftCard < Spree::PaymentMethod # rubocop:disable Style/ClassAndModuleChildren
    def payment_source_class
      ::Spree::VirtualGiftCard
    end

    def authorize(amount_in_cents, provided_store_credit, gateway_options = {})
      if provided_store_credit.nil?
        ActiveMerchant::Billing::Response.new(false, I18n.t('spree.virtual_gift_card.unable_to_find'), {}, {})
      else
        action = ->(virtual_gift_card) {
          virtual_gift_card.authorize(
            amount_in_cents / BigDecimal('100.0'),
            gateway_options[:currency],
            action_originator: gateway_options[:originator]
          )
        }
        handle_action_call(provided_store_credit, action, :authorize)
      end
    end

    def purchase(amount_in_cents, virtual_gift_card, gateway_options = {})
      eligible_events = virtual_gift_card.events.where(amount: amount_in_cents / BigDecimal('100.0'), action: Spree::VirtualGiftCard::ELIGIBLE_ACTION)
      event = eligible_events.find do |eligible_event|
        virtual_gift_card.events.where(authorization_code: eligible_event.authorization_code)
                         .where.not(action: Spree::StoreCredit::ELIGIBLE_ACTION).empty?
      end

      if event.blank?
        ActiveMerchant::Billing::Response.new(false, I18n.t('spree.virtual_gift_card.unable_to_find'), {}, {})
      else
        capture(amount_in_cents, event.authorization_code, gateway_options)
      end
    end

    def capture(amount_in_cents, auth_code, gateway_options = {})
      action = ->(virtual_gift_card) {
        virtual_gift_card.capture(
          amount_in_cents / BigDecimal('100.0'),
          auth_code,
          gateway_options[:currency],
          action_originator: gateway_options[:originator]
        )
      }

      handle_action(action, :capture, auth_code)
    end

    def void(auth_code, gateway_options = {})
      action = ->(virtual_gift_card) {
        virtual_gift_card.void(auth_code, action_originator: gateway_options[:originator])
      }
      handle_action(action, :void, auth_code)
    end

    def credit(amount_in_cents, auth_code, gateway_options = {})
      action = ->(virtual_gift_card) do
        currency = gateway_options[:currency] || virtual_gift_card.currency
        originator = gateway_options[:originator]

        virtual_gift_card.credit(amount_in_cents / BigDecimal('100.0'), auth_code, currency, action_originator: originator)
      end

      handle_action(action, :credit, auth_code)
    end

    def gift_card?
      true
    end

    def partial_name
      "gift_card"
    end

    def can_capture?(payment)
      ['checkout', 'pending'].include?(payment.state)
    end

    private

    def handle_action_call(gift_card, action, action_name, auth_code = nil)
      gift_card.with_lock do
        if response = action.call(gift_card)
          # note that we only need to return the auth code on an 'auth', but it's innocuous to always return
          ActiveMerchant::Billing::Response.new(true,
            I18n.t('spree.virtual_gift_card.successful_action', action: action_name),
            {}, { authorization: auth_code || response })
        else
          ActiveMerchant::Billing::Response.new(false, gift_card.errors.full_messages.join, {}, {})
        end
      end
    end

    def handle_action(action, action_name, auth_code)
      # Find first event with provided auth_code
      virtual_gift_card = Spree::VirtualGiftCardEvent.find_by(authorization_code: auth_code).try(:virtual_gift_card)

      if virtual_gift_card.nil?
        ActiveMerchant::Billing::Response.new(false, I18n.t('spree.virtual_gift_card.unable_to_find_for_action', auth_code:, action: action_name), {}, {})
      else
        handle_action_call(virtual_gift_card, action, action_name, auth_code)
      end
    end

    def auth_or_capture_event(auth_code)
      capture_event = Spree::VirtualGiftCardEvent.find_by(authorization_code: auth_code, action: Spree::StoreCredit::CAPTURE_ACTION)
      auth_event = Spree::VirtualGiftCardEvent.find_by(authorization_code: auth_code, action: Spree::StoreCredit::AUTHORIZE_ACTION)
      capture_event || auth_event
    end
  end
end
