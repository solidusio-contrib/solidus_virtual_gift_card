# frozen_string_literal: true

require 'spec_helper'

describe Spree::VirtualGiftCard do
  let!(:gc_category) { create(:store_credit_gift_card_category) }
  let!(:credit_type) { create(:secondary_credit_type, name: 'Non-expiring') }

  context 'validations' do
    let(:invalid_gift_card) { build(:virtual_gift_card, amount: 0) }

    context 'given an amount less than one' do
      it 'is not valid' do
        expect(invalid_gift_card).not_to be_valid
      end

      it 'adds an error to amount' do
        invalid_gift_card.save
        expect(invalid_gift_card.errors.full_messages).to include 'Amount must be greater than 0'
      end
    end
  end

  describe '#can_deactivate?' do
    subject { gift_card.can_deactivate? }

    let!(:default_refund_reason) { Spree::RefundReason.find_or_create_by!(name: Spree::RefundReason::RETURN_PROCESSING_REASON, mutable: false) }
    let(:gift_card) { create(:redeemable_virtual_gift_card, line_item: order.line_items.first) }

    context 'the order is not complete' do
      let(:order) { create(:order_with_line_items, line_items_count: 1) }

      it "can't deactivate" do
        expect(subject).to be_falsey
      end
    end

    context 'gift card is already deactivated' do
      before { gift_card.deactivate }

      let(:order) { create(:shipped_order, line_items_count: 1) }

      it "can't deactivate" do
        expect(subject).to be_falsey
      end
    end

    context 'order is not paid' do
      let(:order) { create(:order_with_line_items, line_items_count: 1) }

      it "can't deactivate" do
        expect(subject).to be_falsey
      end
    end

    context 'order is paid and complete and gift card is active' do
      let(:order) { create(:shipped_order, line_items_count: 1) }

      it 'can deactivate' do
        expect(subject).to be_truthy
      end
    end
  end

  describe '#deactivate' do
    subject { gift_card.deactivate }

    let!(:gift_card) { create(:redeemable_virtual_gift_card, line_item: order.line_items.first) }
    let(:order) { create(:shipped_order, line_items_count: 1) }
    let!(:default_refund_reason) { Spree::RefundReason.find_or_create_by!(name: Spree::RefundReason::RETURN_PROCESSING_REASON, mutable: false) }

    it 'makes it not redeemable' do
      subject
      expect(gift_card.reload).not_to be_redeemable
    end

    it 'sets the deactivated_at' do
      subject
      expect(gift_card.reload.deactivated_at).to be_present
    end

    it '#deactivated? returns true' do
      subject
      expect(gift_card.reload).to be_deactivated
    end

    it 'cancels the inventory unit' do
      subject
      expect(gift_card.inventory_unit.unit_cancel).to be_present
    end

    it 'creates a reimbursement' do
      expect { subject }.to change(Spree::Reimbursement, :count).by(1)
    end

    it 'returns true' do
      expect(subject).to be_truthy
    end
  end

  describe '#make_redeemable!' do
    subject { gift_card.make_redeemable!(purchaser: user, inventory_unit: inventory_unit) }

    let(:user) { create(:user) }
    let(:gift_card) { create(:virtual_gift_card) }
    let(:order) { create(:shipped_order, line_items_count: 1) }
    let(:inventory_unit) { order.inventory_units.first }

    it 'sets the purchaser' do
      subject
      expect(gift_card.purchaser).to be user
    end

    it 'sets the inventory unit' do
      subject
      expect(gift_card.inventory_unit).to be inventory_unit
    end

    context 'no collision on redemption code' do
      it 'sets a redemption code' do
        subject
        expect(gift_card.redemption_code).to be_present
      end
    end

    context 'redemption code is already set' do
      let(:expected_code) { 'EXPECTEDCODE' }

      before { gift_card.redemption_code = expected_code }

      it 'does not update the redemption code' do
        subject
        expect(gift_card.redemption_code).to eq expected_code
      end
    end

    context 'there is a collision on redemption code' do
      context 'the existing giftcard has not been redeemed yet' do
        let!(:existing_giftcard) { create(:virtual_gift_card, redemption_code: 'ABC123-EFG456') }
        let(:expected_code) { 'EXPECTEDCODE' }
        let(:generator) { Spree::RedemptionCodeGenerator }

        it 'recursively generates redemption codes' do
          expect(generator).to receive(:generate_redemption_code).and_return(existing_giftcard.redemption_code)
          expect(generator).to receive(:generate_redemption_code).and_return(expected_code)

          subject

          expect(gift_card.redemption_code).to eq expected_code
        end
      end

      context 'the existing gift card has been redeemed' do
        let!(:existing_giftcard) { create(:virtual_gift_card, redemption_code: 'ABC123-EFG456', redeemed_at: Time.zone.now) }
        let(:generator) { Spree::RedemptionCodeGenerator }

        it 'recursively generates redemption codes' do
          expect(generator).to receive(:generate_redemption_code).and_return(existing_giftcard.redemption_code)

          subject

          expect(gift_card.redemption_code).to eq existing_giftcard.redemption_code
        end
      end
    end
  end

  describe '#redeemed?' do
    let(:gift_card) { build(:virtual_gift_card) }

    it 'is redeemed if there is a redeemed_at set' do
      gift_card.redeemed_at = Time.zone.now
      expect(gift_card.redeemed?).to be true
    end

    it 'is not redeemed if there is no timestamp for redeemed_at' do
      expect(gift_card.redeemed?).to be false
    end
  end

  describe '#deactivated?' do
    let(:gift_card) { build(:virtual_gift_card) }

    it 'is deactivated if there is a deactivated_at set' do
      gift_card.deactivated_at = Time.zone.now
      expect(gift_card.deactivated?).to be true
    end

    it 'is not deactivated if there is no timestamp for deactivated_at' do
      expect(gift_card.deactivated?).to be false
    end
  end

  describe '#redeem' do
    subject { gift_card.redeem(redeemer) }

    let(:gift_card) { create(:redeemable_virtual_gift_card) }
    let(:redeemer) { create(:user) }

    context 'it is not redeemable' do
      before { gift_card.redeemable = false }

      it 'returns false' do
        expect(subject).to be false
      end

      context 'does nothing to the gift card' do
        it 'does not create a store credit' do
          expect(gift_card.store_credit).not_to be_present
        end

        it 'does not update the gift card' do
          expect { subject }.not_to change{ gift_card }
        end
      end
    end

    context 'it has been deactivated' do
      before do
        expect(gift_card).to receive(:cancel_and_reimburse_inventory_unit).and_return(true)
        gift_card.deactivate
      end

      it 'returns false' do
        expect(subject).to be false
      end

      context 'does nothing to the gift card' do
        it 'does not create a store credit' do
          expect(gift_card.store_credit).not_to be_present
        end

        it 'does not update the gift card' do
          expect { subject }.not_to change{ gift_card }
        end
      end
    end

    context 'it has already been redeemed' do
      before { gift_card.redeemed_at = Date.yesterday }

      it 'returns false' do
        expect(subject).to be false
      end

      context 'does nothing to the gift card' do
        it 'does not create a store credit' do
          expect(gift_card.store_credit).not_to be_present
        end

        it 'does not update the gift card' do
          expect { subject }.not_to change{ gift_card }
        end
      end
    end

    context 'it has not been redeemed already and is redeemable' do
      context 'generates a store credit' do
        before { subject }

        let(:store_credit) { gift_card.store_credit }

        it 'sets the relationship' do
          expect(store_credit).to be_present
        end

        it 'sets the store credit amount' do
          expect(store_credit.amount).to eq gift_card.amount
        end

        it 'sets the store credit currency' do
          expect(store_credit.currency).to eq gift_card.currency
        end

        it "sets the 'Gift Card' category" do
          expect(store_credit.category).to eq gc_category
        end

        it 'sets the redeeming user on the store credit' do
          expect(store_credit.user).to eq redeemer
        end

        it 'sets the created_by user on the store credit' do
          expect(store_credit.created_by).to eq redeemer
        end

        it 'sets a memo on store credit for admins to reference the redemption code' do
          expect(store_credit.memo).to eq gift_card.memo
        end
      end

      it 'returns true' do
        expect(subject).to be true
      end

      it 'sets redeemed_at' do
        subject
        expect(gift_card.redeemed_at).to be_present
      end

      it 'sets the redeeming user association' do
        subject
        expect(gift_card.redeemer).to be_present
      end

      it 'sets the admin as the store credit event originator' do
        expect { subject }.to change(Spree::StoreCreditEvent, :count).by(1)
        expect(Spree::StoreCreditEvent.last.originator).to eq gift_card
      end
    end
  end

  describe '#formatted_redemption_code' do
    subject { gift_card.formatted_redemption_code }

    let(:formatted_redemption_code) { 'AAAA-BBBB-CCCC-DDDD' }
    let(:gift_card) { build(:redeemable_virtual_gift_card, redemption_code: 'AAAABBBBCCCCDDDD') }

    it 'inserts dashes into the code after every 4 characters' do
      expect(subject).to eq formatted_redemption_code
    end
  end

  describe '#send_email' do
    subject { gift_card.send_email }

    let(:gift_card) { create(:redeemable_virtual_gift_card) }

    it 'sends the gift card email' do
      expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card).and_return(double(deliver_later: true))
      subject
    end

    it 'sets sent_at' do
      expect { subject }.to change(gift_card, :sent_at)
    end
  end

  describe "#authorize" do
    let(:virtual_gift_card) { create(:virtual_gift_card, amount: 4) }

    context "amount is valid" do
      let(:virtual_gift_card) { create(:virtual_gift_card, amount: authorization_amount + added_authorization_amount, amount_authorized: authorization_amount) }

      let(:authorization_amount)       { 1.0 }
      let(:added_authorization_amount) { 3.0 }
      let(:originator) { nil }

      context "amount has not been authorized yet" do
        before { virtual_gift_card.update(amount_authorized: authorization_amount) }

        it "returns true" do
          expect(virtual_gift_card.authorize(virtual_gift_card.amount - authorization_amount, virtual_gift_card.currency)).to be_truthy
        end

        it "adds the new amount to authorized amount" do
          virtual_gift_card.authorize(added_authorization_amount, virtual_gift_card.currency)
          expect(virtual_gift_card.reload.amount_authorized).to eq(authorization_amount + added_authorization_amount)
        end

        context "originator is present" do
          subject { virtual_gift_card.authorize(added_authorization_amount, virtual_gift_card.currency, action_originator: originator) }
          let(:originator) { create(:user) } # won't actually be a user. just giving it a valid model here

          it "records the originator" do
            expect { subject }.to change(Spree::VirtualGiftCardEvent, :count).by(1)
            expect(Spree::VirtualGiftCardEvent.last.originator).to eq originator
          end
        end
      end

      context "authorization has already happened" do
        let!(:auth_event) { create(:virtual_gift_card_auth_event, virtual_gift_card:) }

        before { virtual_gift_card.update(amount_authorized: virtual_gift_card.amount) }

        it "returns true" do
          expect(virtual_gift_card.authorize(virtual_gift_card.amount, virtual_gift_card.currency, action_authorization_code: auth_event.authorization_code)).to be true
        end
      end
    end

    context "amount is invalid" do
      it "returns false" do
        expect(virtual_gift_card.authorize(virtual_gift_card.amount * 2, virtual_gift_card.currency)).to be false
      end
    end
  end

  describe "#validate_authorization" do
    let(:virtual_gift_card) { create(:virtual_gift_card) }

    context "insufficient funds" do
      subject { virtual_gift_card.validate_authorization(virtual_gift_card.amount * 2, virtual_gift_card.currency) }

      it "returns false" do
        expect(subject).to be false
      end

      it "adds an error to the model" do
        subject
        expect(virtual_gift_card.errors.full_messages).to include("Gift Card amount remaining is not sufficient")
      end
    end

    context "currency mismatch" do
      subject { virtual_gift_card.validate_authorization(virtual_gift_card.amount, "EUR") }

      it "returns false" do
        expect(subject).to be false
      end

      it "adds an error to the model" do
        subject
        expect(virtual_gift_card.errors.full_messages).to include("Gift Card currency does not match order currency")
      end
    end

    context "valid authorization" do
      subject { virtual_gift_card.validate_authorization(virtual_gift_card.amount, virtual_gift_card.currency) }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context 'troublesome floats' do
      if Gem::Requirement.new("~> 3.0.0") === Gem::Version.new(BigDecimal::VERSION) # rubocop:disable Style/CaseEquality
        # BigDecimal 2.0.0> 8.21.to_d # => 0.821e1 (all good!)
        # BigDecimal 3.0.0> 8.21.to_d # => 0.8210000000000001e1 (`8.21.to_d < 8.21` is `true`!!!)
        # BigDecimal 3.1.4> 8.21.to_d # => 0.821e1 (all good!)
        before { pending "https://github.com/rails/rails/issues/42098; https://github.com/ruby/bigdecimal/issues/192" }
      end

      subject { virtual_gift_card.validate_authorization(store_credit_attrs[:amount], virtual_gift_card.currency) }

      let(:store_credit_attrs) { { amount: 8.21 } }

      it { is_expected.to be_truthy }
    end
  end

  describe "#capture" do
    let(:virtual_gift_card) { create(:virtual_gift_card, amount: authorized_amount * 2, amount_authorized: authorized_amount) }
    let(:authorized_amount) { 10.00 }
    let(:auth_code) { "23-GC-20140602164814476128" }
    let(:authorized_code) { virtual_gift_card.authorize(authorized_amount, virtual_gift_card.currency) }

    before do
      @original_authed_amount = virtual_gift_card.amount_authorized
    end

    context "insufficient funds" do
      subject { virtual_gift_card.capture(authorized_amount * 2, authorized_code, virtual_gift_card.currency) }

      it "returns false" do
        expect(subject).to be false
      end

      it "adds an error to the model" do
        subject
        expect(virtual_gift_card.errors.full_messages).to include("Unable to capture more than authorized amount")
      end

      it "does not update the virtual gift card model" do
        expect { subject }.not_to change { virtual_gift_card }
      end
    end

    context "currency mismatch" do
      subject { virtual_gift_card.capture(authorized_amount, authorized_code, "EUR") }

      it "returns false" do
        expect(subject).to be false
      end

      it "adds an error to the model" do
        subject
        expect(virtual_gift_card.errors.full_messages).to include("Gift Card currency does not match order currency")
      end

      it "does not update the virtual gift card model" do
        expect { subject }.not_to change { virtual_gift_card }
      end
    end

    context "valid capture" do
      subject { virtual_gift_card.capture(authorized_amount - remaining_authorized_amount, @auth_code, virtual_gift_card.currency, action_originator: originator) } # rubocop:disable RSpec/InstanceVariable

      before do
        @auth_code = virtual_gift_card.authorize(authorized_amount, virtual_gift_card.currency)
      end

      let(:remaining_authorized_amount) { 1 }
      let(:originator) { nil }

      it "returns true" do
        expect(subject).to be_truthy
      end

      it "updates the authorized amount to the difference between the virtual gift card total authed amount and the authorized amount for this event" do
        subject
        expect(virtual_gift_card.reload.amount_authorized).to eq(@original_authed_amount) # rubocop:disable RSpec/InstanceVariable
      end

      it "updates the used amount to the current used amount plus the captured amount" do
        subject
        expect(virtual_gift_card.reload.amount_used).to eq authorized_amount - remaining_authorized_amount
      end

      context "originator is present" do
        let(:originator) { create(:user) } # won't actually be a user. just giving it a valid model here

        it "records the originator" do
          expect { subject }.to change(Spree::VirtualGiftCardEvent, :count).by(1)
          expect(Spree::VirtualGiftCardEvent.last.originator).to eq originator
        end
      end
    end
  end

  describe "#void" do
    subject(:void_payment) do
      virtual_gift_card.void(auth_code, action_originator: originator)
    end

    let(:auth_code) { "1-SC-20141111111111" }
    let(:virtual_gift_card) { create(:virtual_gift_card, amount: 150) }
    let(:originator) { nil }

    context "without event for auth_code" do
      it "returns false" do
        expect(void_payment).to be false
      end

      it "adds an error to the model" do
        void_payment
        expect(virtual_gift_card.errors.full_messages).to include("Unable to void code: #{auth_code}")
      end
    end

    context "with capture event for auth_code" do
      let(:captured_amount) { 10.0 }
      let!(:capture_event) {
        create(:virtual_gift_card_auth_event,
          action: Spree::VirtualGiftCard::CAPTURE_ACTION,
          authorization_code: auth_code,
          amount: captured_amount,
          virtual_gift_card:)
      }

      it "returns false" do
        expect(void_payment).to be false
      end

      it "does not change the amount used on the store credit" do
        expect { void_payment }.not_to change{ virtual_gift_card.amount_used.to_f }
      end
    end

    context "with auth event for auth_code" do
      let(:authorized_amount) { 10.0 }
      let(:auth_event) {
        create(:virtual_gift_card_auth_event,
          authorization_code: auth_code,
          amount: authorized_amount,
          virtual_gift_card:)
      }

      before do
        auth_event
      end

      it "returns true" do
        expect(void_payment).to be true
      end

      it "returns the authorized amount to the virtual gift card" do
        expect { void_payment }.to change{ virtual_gift_card.amount_authorized.to_f }.by(-authorized_amount)
      end

      context "when originator is present" do
        let(:originator) { create(:user) } # won't actually be a user. just giving it a valid model here

        it "records the originator" do
          expect { void_payment }.to change(Spree::VirtualGiftCardEvent, :count).by(1)
          expect(Spree::VirtualGiftCardEvent.last.originator).to eq originator
        end
      end
    end
  end
end
