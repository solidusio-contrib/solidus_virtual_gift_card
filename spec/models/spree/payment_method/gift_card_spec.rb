require 'spec_helper'

RSpec.describe Spree::PaymentMethod::GiftCard do
  let(:order)           { create(:order) }
  let(:payment)         { create(:payment, order:) }
  let(:gateway_options) { payment.gateway_options }

  describe "#authorize" do
    subject(:authorize) do
      described_class.new.authorize(auth_amount, virtual_gift_card, gateway_options)
    end

    let(:auth_amount) { virtual_gift_card.amount_remaining * 100 }
    let(:virtual_gift_card) { create(:virtual_gift_card) }
    let(:gateway_options) { super().merge(originator:) }
    let(:originator) { nil }

    context 'without an invalid virtual gift card' do
      let(:virtual_gift_card) { nil }
      let(:auth_amount) { 10 }

      it "declines an unknown store gift card" do
        expect(authorize).not_to be_success
        expect(authorize.message).to include I18n.t('spree.virtual_gift_card.unable_to_find')
      end
    end

    context 'with insuffient funds' do
      let(:auth_amount) { (virtual_gift_card.amount_remaining * 100) + 1 }

      it "declines a gift card" do
        expect(authorize).not_to be_success
        expect(authorize.message).to include I18n.t('spree.virtual_gift_card.insufficient_funds')
      end
    end

    context 'when the currency does not match the order currency' do
      let(:virtual_gift_card) { create(:virtual_gift_card, currency: 'AUD') }

      it "declines the credit" do
        expect(authorize).not_to be_success
        expect(authorize.message).to include I18n.t('spree.virtual_gift_card.currency_mismatch')
      end
    end

    context 'with a valid request' do
      it "authorizes a valid gift card" do
        expect(authorize).to be_success
        expect(authorize.authorization).not_to be_nil
      end

      context 'with an originator' do
        let(:originator) { double('originator') } # rubocop:disable RSpec/VerifiedDoubles

        it 'passes the originator' do
          expect_any_instance_of(Spree::VirtualGiftCard).to receive(:authorize) # rubocop:disable RSpec/AnyInstance
            .with(anything, anything, action_originator: originator)
          authorize
        end
      end
    end
  end

  describe "#capture" do
    subject(:capture) do
      described_class.new.capture(capture_amount, auth_code, gateway_options)
    end

    let(:capture_amount) { 10_00 }
    let(:auth_code) { auth_event.authorization_code }
    let(:gateway_options) { super().merge(originator:) }

    let(:authorized_amount) { capture_amount / 100.0 }
    let(:auth_event) { create(:virtual_gift_card_auth_event, virtual_gift_card:, amount: authorized_amount) }
    let(:virtual_gift_card) { create(:virtual_gift_card, amount_authorized: authorized_amount) }
    let(:originator) { nil }

    context 'with an invalid auth code' do
      let(:auth_code) { -1 }

      it "declines an unknown virtual gift card" do
        expect(capture).not_to be_success
        expect(capture.message).to include I18n.t('spree.virtual_gift_card.unable_to_find')
      end
    end

    context 'when unable to authorize the amount' do
      let(:authorized_amount) { (capture_amount - 1) / 100 }

      before do
        allow_any_instance_of(Spree::VirtualGiftCard).to receive_messages(authorize: true) # rubocop:disable RSpec/AnyInstance
      end

      it "declines a store credit" do
        expect(capture).not_to be_success
        expect(capture.message).to include I18n.t('spree.virtual_gift_card.insufficient_authorized_amount')
      end
    end

    context 'when the currency does not match the order currency' do
      let(:virtual_gift_card) { create(:virtual_gift_card, currency: 'AUD', amount_authorized: authorized_amount) }

      it "declines the credit" do
        expect(capture).not_to be_success
        expect(capture.message).to include I18n.t('spree.virtual_gift_card.currency_mismatch')
      end
    end

    context 'with a valid request' do
      it "captures the gift card" do
        expect(capture.message).to include I18n.t('spree.virtual_gift_card.successful_action', action: Spree::VirtualGiftCard::CAPTURE_ACTION)
        expect(capture).to be_success
      end

      context 'with an originator' do
        let(:originator) { double('originator') } # rubocop:disable RSpec/VerifiedDoubles

        it 'passes the originator' do
          expect_any_instance_of(Spree::VirtualGiftCard).to receive(:capture) # rubocop:disable RSpec/AnyInstance
            .with(anything, anything, anything, action_originator: originator)
          capture
        end
      end
    end
  end

  describe "#purchase" do
    subject(:gift_card_payment_method) do
      described_class.new
    end

    it "declines a purchase if it can't find a pending credit for the correct amount" do
      amount = 100.0
      virtual_gift_card = create(:virtual_gift_card)
      auth_code = virtual_gift_card.generate_authorization_code
      virtual_gift_card.events.create!(action: Spree::VirtualGiftCard::ELIGIBLE_ACTION,
        amount:,
        authorization_code: auth_code)
      virtual_gift_card.events.create!(action: Spree::VirtualGiftCard::CAPTURE_ACTION,
        amount:,
        authorization_code: auth_code)

      resp = gift_card_payment_method.purchase(amount * 100.0, virtual_gift_card, gateway_options)
      expect(resp.success?).to be false
      expect(resp.message).to include I18n.t('spree.virtual_gift_card.unable_to_find')
    end

    it "captures a purchase if it can find a pending credit for the correct amount" do
      amount = 100.0
      virtual_gift_card = create(:virtual_gift_card, amount: 150)
      auth_code = virtual_gift_card.generate_authorization_code
      virtual_gift_card.events.create!(action: Spree::VirtualGiftCard::ELIGIBLE_ACTION,
        amount:,
        authorization_code: auth_code)

      resp = gift_card_payment_method.purchase(amount * 100.0, virtual_gift_card, gateway_options)
      expect(resp.success?).to be true
      expect(resp.message).to include I18n.t('spree.virtual_gift_card.successful_action', action: Spree::VirtualGiftCard::CAPTURE_ACTION)
    end
  end
end
