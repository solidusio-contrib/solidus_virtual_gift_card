require 'spec_helper'

shared_examples "check total store credit from payments" do
  context "with valid payments" do
    let(:order)           { payment.order }
    let!(:payment)        { create(:store_credit_payment) }
    let!(:second_payment) { create(:store_credit_payment, order: order) }

    subject { order }

    it "returns the sum of the payment amounts" do
      expect(subject.total_applicable_store_credit).to eq (payment.amount + second_payment.amount)
    end
  end

  context "without valid payments" do
    let(:order) { create(:order) }

    subject { order }

    it "returns 0" do
      expect(subject.total_applicable_store_credit).to be_zero
    end
  end
end

describe "Order" do
  describe "#create_gift_cards" do
    let(:order) { create(:order_with_line_items) }
    let(:line_item) { order.line_items.first }
    subject { order.create_gift_cards }

    context "the line item is a gift card" do
      before do
        allow(line_item).to receive(:gift_card?).and_return(true)
        allow(line_item).to receive(:quantity).and_return(3)
      end

      it 'creates a gift card for each gift card in the line item' do
        expect { subject }.to change { Spree::VirtualGiftCard.count }.by(line_item.quantity)
      end

      it 'sets the purchaser, amount, and currency' do
        expect(Spree::VirtualGiftCard).to receive(:create!).exactly(3).times.with(amount: line_item.price, currency: line_item.currency, purchaser: order.user, line_item: line_item)
        subject
      end
    end

    context "the line item is not a gift card" do
      before { allow(line_item).to receive(:gift_card?).and_return(false) }

      it 'does not create a gift card' do
        expect(Spree::VirtualGiftCard).not_to receive(:create!)
        subject
      end
    end
  end

  describe "#add_store_credit_payments" do
    let(:order_total) { 500.00 }

    before { create(:store_credit_payment_method) }

    subject { order.add_store_credit_payments }

    context "there is no store credit" do
      let(:order)       { create(:store_credits_order_without_user, total: order_total) }

      context "there is a credit card payment" do
        let!(:cc_payment) { create(:payment, order: order) }

        before do
          # callbacks recalculate total based on line items
          # this ensures the total is what we expect
          order.update_column(:total, order_total)
          subject
          order.reload
        end

        it "charges the outstanding balance to the credit card" do
          expect(order.payments.count).to eq 1
          expect(order.payments.first.source).to be_a(Spree::CreditCard)
          expect(order.payments.first.amount).to eq order_total
        end
      end

      context "there are no other payments" do
        it "adds an error to the model" do
          expect(subject).to be false
          expect(order.errors.full_messages).to include(Spree.t("store_credit.errors.unable_to_fund"))
        end
      end

      context "there is a payment of an unknown type" do
        let!(:check_payment) { create(:check_payment, order: order) }

        it "raises an error" do
          expect { subject }.to raise_error
        end
      end
    end

    context "there is enough store credit to pay for the entire order" do
      let(:store_credit) { create(:store_credit, amount: order_total) }
      let(:order)        { create(:order, user: store_credit.user, total: order_total) }

      context "there are no other payments" do
        before do
          subject
          order.reload
        end

        it "creates a store credit payment for the full amount" do
          expect(order.payments.count).to eq 1
          expect(order.payments.first).to be_store_credit
          expect(order.payments.first.amount).to eq order_total
        end
      end

      context "there is a credit card payment" do
        it "invalidates the credit card payment" do
          cc_payment = create(:payment, order: order)
          expect { subject }.to change { cc_payment.reload.state }.to 'invalid'
        end
      end

      context "there is a payment of an unknown type" do
        let!(:check_payment) { create(:check_payment, order: order) }

        it "raises an error" do
          expect { subject }.to raise_error
        end
      end
    end

    context "the available store credit is not enough to pay for the entire order" do
      let(:expected_cc_total)  { 100.0 }
      let(:store_credit_total) { order_total - expected_cc_total }
      let(:store_credit)       { create(:store_credit, amount: store_credit_total) }
      let(:order)              { create(:order, user: store_credit.user, total: order_total) }


      context "there are no other payments" do
        it "adds an error to the model" do
          expect(subject).to be false
          expect(order.errors.full_messages).to include(Spree.t("store_credit.errors.unable_to_fund"))
        end
      end

      context "there is a credit card payment" do
        let!(:cc_payment) { create(:payment, order: order) }

        before do
          # callbacks recalculate total based on line items
          # this ensures the total is what we expect
          order.update_column(:total, order_total)
          subject
          order.reload
        end

        it "charges the outstanding balance to the credit card" do
          expect(order.payments.count).to eq 2
          expect(order.payments.first.source).to be_a(Spree::CreditCard)
          expect(order.payments.first.amount).to eq expected_cc_total
        end
      end

      context "there is a payment of an unknown type" do
        let!(:check_payment) { create(:check_payment, order: order) }

        it "raises an error" do
          expect { subject }.to raise_error
        end
      end
    end

    context "there are multiple store credits" do
      context "they have different credit type priorities" do
        let(:amount_difference)       { 100 }
        let!(:primary_store_credit)   { create(:store_credit, amount: (order_total - amount_difference)) }
        let!(:secondary_store_credit) { create(:store_credit, amount: order_total, user: primary_store_credit.user, credit_type: create(:secondary_credit_type)) }
        let(:order)                   { create(:order, user: primary_store_credit.user, total: order_total) }

        before do
          subject
          order.reload
        end

        it "uses the primary store credit type over the secondary" do
          primary_payment = order.payments.first
          secondary_payment = order.payments.last

          expect(order.payments.size).to eq 2
          expect(primary_payment.source).to eq primary_store_credit
          expect(secondary_payment.source).to eq secondary_store_credit
          expect(primary_payment.amount).to eq(order_total - amount_difference)
          expect(secondary_payment.amount).to eq(amount_difference)
        end
      end
    end
  end

  describe "#covered_by_store_credit" do
    context "order doesn't have an associated user" do
      subject { create(:store_credits_order_without_user) }

      it "returns false" do
        expect(subject.covered_by_store_credit).to be false
      end
    end

    context "order has an associated user" do
      let(:user) { create(:user) }

      subject    { create(:order, user: user) }

      context "user has enough store credit to pay for the order" do
        before do
          allow(user).to receive_messages(total_available_store_credit: 10.0)
          allow(subject).to receive_messages(total: 5.0)
        end

        it "returns true" do
          expect(subject.covered_by_store_credit).to be true
        end
      end

      context "user does not have enough store credit to pay for the order" do
        before do
          allow(user).to receive_messages(total_available_store_credit: 0.0)
          allow(subject).to receive_messages(total: 5.0)
        end

        it "returns false" do
          expect(subject.covered_by_store_credit).to be false
        end
      end
    end
  end

  describe "#total_available_store_credit" do
    context "order does not have an associated user" do
      subject { create(:store_credits_order_without_user) }

      it "returns 0" do
        expect(subject.total_available_store_credit).to be_zero
      end
    end

    context "order has an associated user" do
      let(:user)                   { create(:user) }
      let(:available_store_credit) { 25.0 }

      subject { create(:order, user: user) }

      before do
        allow(user).to receive_messages(total_available_store_credit: available_store_credit)
      end

      it "returns the user's available store credit" do
        expect(subject.total_available_store_credit).to eq available_store_credit
      end
    end
  end

  describe "#order_total_after_store_credit" do
    let(:order_total) { 100.0 }

    subject { create(:order, total: order_total) }

    before do
      allow(subject).to receive_messages(total_applicable_store_credit: applicable_store_credit)
    end

    context "order's user has store credits" do
      let(:applicable_store_credit) { 10.0 }

      it "deducts the applicable store credit" do
        expect(subject.order_total_after_store_credit).to eq (order_total - applicable_store_credit)
      end
    end

    context "order's user does not have any store credits" do
      let(:applicable_store_credit) { 0.0 }

      it "returns the order total" do
        expect(subject.order_total_after_store_credit).to eq order_total
      end
    end
  end

  describe "#finalize!" do
    context "the order contains gift cards and transitions to complete" do
      let(:order) { create(:order_with_line_items, state: 'complete') }

      subject { order.finalize! }

      it "calls #create_gift_cards" do
        expect(order).to receive(:create_gift_cards)
        subject
      end
    end
  end

  describe "transition to complete" do
    let(:order) { create(:order_with_line_items, state: 'confirm') }
    let!(:payment) { create(:payment, order: order, state: 'pending') }
    subject { order.complete! }

    it "calls #send_gift_card_emails" do
      expect(order).to receive(:send_gift_card_emails)
      subject
    end

  end

  describe "#send_gift_card_emails" do

    subject { order.send_gift_card_emails }

    context "the order has gift cards" do
      let(:gift_card) { create(:virtual_gift_card) }
      let(:line_item) { gift_card.line_item }
      let(:gift_card_2) { create(:virtual_gift_card, line_item: line_item) }
      let(:order) { gift_card.line_item.order }

      it "should call GiftCardMailer#send" do
        expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card).and_return(double(deliver: true))
        expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card_2).and_return(double(deliver: true))
        subject
      end
    end

    context "no gift cards" do
      let(:order) { create(:order_with_line_items) }

      it "should not call GiftCardMailer#send" do
        expect(Spree::GiftCardMailer).to_not receive(:gift_card_email)
        subject
      end
    end
  end

  describe "#total_applicable_store_credit" do
    context "order is in the confirm state" do
      before { order.update_attributes(state: 'confirm') }
      include_examples "check total store credit from payments"
    end

    context "order is completed" do
      before { order.update_attributes(state: 'complete') }
      include_examples "check total store credit from payments"
    end

    context "order is in any state other than confirm or complete" do
      context "the associated user has store credits" do
        let(:store_credit) { create(:store_credit) }
        let(:order)        { create(:order, user: store_credit.user) }

        subject { order }

        context "the store credit is more than the order total" do
          let(:order_total) { store_credit.amount - 1 }

          before { order.update_attributes(total: order_total) }

          it "returns the order total" do
            expect(subject.total_applicable_store_credit).to eq order_total
          end
        end

        context "the store credit is less than the order total" do
          let(:order_total) { store_credit.amount * 10 }

          before { order.update_attributes(total: order_total) }

          it "returns the store credit amount" do
            expect(subject.total_applicable_store_credit).to eq store_credit.amount
          end
        end
      end

      context "the associated user does not have store credits" do
        let(:order) { create(:order) }

        subject { order }

        it "returns 0" do
          expect(subject.total_applicable_store_credit).to be_zero
        end
      end

      context "the order does not have an associated user" do
        subject { create(:store_credits_order_without_user) }

        it "returns 0" do
          expect(subject.total_applicable_store_credit).to be_zero
        end
      end
    end
  end

  describe "#display_total_applicable_store_credit" do
    let(:total_applicable_store_credit) { 10.00 }

    subject { create(:order) }

    before { allow(subject).to receive_messages(total_applicable_store_credit: total_applicable_store_credit) }

    it "returns a money instance" do
      expect(subject.display_total_applicable_store_credit).to be_a(Spree::Money)
    end

    it "returns a negative amount" do
      expect(subject.display_total_applicable_store_credit.money.cents).to eq (total_applicable_store_credit * -100.0)
    end
  end

  describe "#display_order_total_after_store_credit" do
    let(:order_total_after_store_credit) { 10.00 }

    subject { create(:order) }

    before { allow(subject).to receive_messages(order_total_after_store_credit: order_total_after_store_credit) }

    it "returns a money instance" do
      expect(subject.display_order_total_after_store_credit).to be_a(Spree::Money)
    end

    it "returns the order_total_after_store_credit amount" do
      expect(subject.display_order_total_after_store_credit.money.cents).to eq (order_total_after_store_credit * 100.0)
    end
  end

  describe "#display_total_available_store_credit" do
    let(:total_available_store_credit) { 10.00 }

    subject { create(:order) }

    before { allow(subject).to receive_messages(total_available_store_credit: total_available_store_credit) }

    it "returns a money instance" do
      expect(subject.display_total_available_store_credit).to be_a(Spree::Money)
    end

    it "returns the total_available_store_credit amount" do
      expect(subject.display_total_available_store_credit.money.cents).to eq (total_available_store_credit * 100.0)
    end
  end

  describe "#display_store_credit_remaining_after_capture" do
    let(:total_available_store_credit)  { 10.00 }
    let(:total_applicable_store_credit) { 5.00 }

    subject { create(:order) }

    before do
      allow(subject).to receive_messages(total_available_store_credit: total_available_store_credit,
                   total_applicable_store_credit: total_applicable_store_credit)
    end

    it "returns a money instance" do
      expect(subject.display_store_credit_remaining_after_capture).to be_a(Spree::Money)
    end

    it "returns all of the user's available store credit minus what's applied to the order amount" do
      amount_remaining = total_available_store_credit - total_applicable_store_credit
      expect(subject.display_store_credit_remaining_after_capture.money.cents).to eq (amount_remaining * 100.0)
    end
  end
end
