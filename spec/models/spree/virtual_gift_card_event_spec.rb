# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::VirtualGiftCardEvent do
  describe ".exposed_events" do
    [
      Spree::VirtualGiftCard::ELIGIBLE_ACTION,
      Spree::VirtualGiftCard::AUTHORIZE_ACTION
    ].each do |action|
      let(:action) { action }
      it "excludes #{action} actions" do
        event = create(:virtual_gift_card_event, action:)
        expect(described_class.exposed_events).not_to include event
      end
    end

    [
      Spree::VirtualGiftCard::VOID_ACTION,
      Spree::VirtualGiftCard::CREDIT_ACTION,
      Spree::VirtualGiftCard::CAPTURE_ACTION,
      Spree::VirtualGiftCard::ALLOCATION_ACTION
    ].each do |action|
      it "includes #{action} actions" do
        event = create(:virtual_gift_card_event, action:)
        expect(described_class.exposed_events).to include event
      end
    end

    it "excludes invalidated virtual gift card events" do
      deactivated_virtual_gift_card = create(:virtual_gift_card, deactivated_at: Time.current)
      event = create(:virtual_gift_card_event, action: Spree::VirtualGiftCard::VOID_ACTION, virtual_gift_card: deactivated_virtual_gift_card)
      expect(described_class.exposed_events).not_to include event
    end
  end

  describe "update virtual gift card reason validation" do
    context "with adjustment event" do
      context "with a gift card reason" do
        let(:event) { build(:virtual_gift_card_adjustment_event) }

        it "returns true" do
          expect(event).to be_valid
        end
      end
    end

    context "with invalidate event" do
      context "with a virtual gift card reason" do
        let(:event) { build(:virtual_gift_card_invalidate_event) }

        it "returns true" do
          expect(event).to be_valid
        end
      end
    end

    context "when event doesn't require a store credit reason" do
      let(:event) { build(:virtual_gift_card_auth_event) }

      it "returns true" do
        expect(event).to be_valid
      end
    end
  end

  describe "#capture_action?" do
    context "with capture events" do
      let(:event) { create(:virtual_gift_card_capture_event) }

      it "returns true" do
        expect(event).to be_capture_action
      end
    end

    context "with non-capture events" do
      let(:event) { create(:virtual_gift_card_auth_event) }

      it "returns false" do
        expect(event).not_to be_capture_action
      end
    end
  end

  describe "#authorization_action?" do
    context "with auth events" do
      let(:event) { create(:virtual_gift_card_auth_event) }

      it "returns true" do
        expect(event).to be_authorization_action
      end
    end

    context "with non-auth events" do
      let(:event) { create(:virtual_gift_card_capture_event) }

      it "returns false" do
        expect(event).not_to be_authorization_action
      end
    end
  end

  describe "#display_amount" do
    subject(:auth_event) { create(:virtual_gift_card_auth_event, amount: event_amount) }

    let(:event_amount) { 120.0 }

    it "returns a Spree::Money instance" do
      expect(auth_event.display_amount).to be_instance_of(Spree::Money)
    end

    it "uses the events amount attribute" do
      expect(auth_event.display_amount).to eq Spree::Money.new(event_amount, { currency: auth_event.currency })
    end
  end

  describe "#display_user_total_amount" do
    subject(:auth_event) { create(:virtual_gift_card_auth_event, user_total_amount:) }

    let(:user_total_amount) { 300.0 }

    it "returns a Spree::Money instance" do
      expect(auth_event.display_user_total_amount).to be_instance_of(Spree::Money)
    end

    it "uses the events user_total_amount attribute" do
      expect(auth_event.display_user_total_amount).to eq Spree::Money.new(user_total_amount, { currency: auth_event.currency })
    end
  end

  describe "#display_remaining_amount" do
    subject(:auth_event) { create(:virtual_gift_card_auth_event, amount_remaining:) }

    let(:amount_remaining) { 300.0 }

    it "returns a Spree::Money instance" do
      expect(auth_event.display_remaining_amount).to be_instance_of(Spree::Money)
    end

    it "uses the events amount_remaining attribute" do
      expect(auth_event.display_remaining_amount).to eq Spree::Money.new(amount_remaining, { currency: auth_event.currency })
    end
  end

  describe "#display_event_date" do
    subject(:auth_event) { create(:virtual_gift_card_auth_event, created_at: date) }

    let(:date) { Time.zone.parse("2014-06-01") }

    it "returns the date the event was created with the format month/date/year" do
      expect(auth_event.display_event_date).to eq "June 01, 2014"
    end
  end

  describe "#display_action" do
    context "with capture event" do
      let(:event) { create(:virtual_gift_card_capture_event) }

      it "returns the action's display text" do
        expect(event.display_action).to eq "Used"
      end
    end

    context "with allocation event" do
      let(:event) { create(:virtual_gift_card_event, action: Spree::VirtualGiftCard::ALLOCATION_ACTION) }

      it "returns the action's display text" do
        expect(event.display_action).to eq "Added"
      end
    end

    context "with void event" do
      let(:event) { create(:virtual_gift_card_event, action: Spree::VirtualGiftCard::VOID_ACTION) }

      it "returns the action's display text" do
        expect(event.display_action).to eq "Credit"
      end
    end

    context "with credit event" do
      let(:event) { create(:virtual_gift_card_event, action: Spree::VirtualGiftCard::CREDIT_ACTION) }

      it "returns the action's display text" do
        expect(event.display_action).to eq "Credit"
      end
    end

    context "with adjustment event" do
      let(:event) { create(:virtual_gift_card_adjustment_event) }

      it "returns the action's display text" do
        expect(event.display_action).to eq "Adjustment"
      end
    end

    context "with authorize event" do
      let(:event) { create(:virtual_gift_card_auth_event) }

      it "returns nil" do
        expect(event.display_action).to be_nil
      end
    end

    context "with eligible event" do
      let(:event) { create(:virtual_gift_card_event, action: Spree::VirtualGiftCard::ELIGIBLE_ACTION) }

      it "returns nil" do
        expect(event.display_action).to be_nil
      end
    end
  end

  describe "#order" do
    context "when there is no associated payment with the event" do
      it "returns nil" do
        expect(create(:virtual_gift_card_auth_event).order).to be_nil
      end
    end

    context "with an associated payment with the event" do
      subject(:auth_event) { create(:virtual_gift_card_auth_event, action: Spree::VirtualGiftCard::CAPTURE_ACTION, authorization_code:) }

      let(:authorization_code) { "1-GC-TEST" }
      let(:order)              { create(:order) }

      before do
        create(:gift_card_payment, order:, response_code: authorization_code)
      end

      it "returns the order associated with the payment" do
        expect(auth_event.order).to eq order
      end
    end
  end
end
