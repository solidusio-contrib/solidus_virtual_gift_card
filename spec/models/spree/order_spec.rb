# frozen_string_literal: true

require 'spec_helper'

describe Spree::Order do
  describe '#finalize' do
    context 'the order contains gift cards and transitions to complete' do
      subject { order.finalize }

      let(:gift_card) { create(:virtual_gift_card) }
      let(:order) { create(:order_with_line_items, state: 'complete', line_items: [gift_card.line_item]) }

      it 'makes the gift card redeemable' do
        subject
        expect(gift_card.reload.redeemable).to be true
        expect(gift_card.reload.redemption_code).to be_present
      end
    end
  end

  describe '#send_gift_card_emails' do
    subject { order.send_gift_card_emails }

    context 'the order has gift cards' do
      let(:gift_card) { create(:virtual_gift_card, send_email_at: send_email_at) }
      let(:line_item) { gift_card.line_item }
      let(:gift_card_2) { create(:virtual_gift_card, line_item: line_item, send_email_at: send_email_at) }
      let(:order) { gift_card.line_item.order }

      context 'send_email_at is not set' do
        let(:send_email_at) { nil }

        it 'calls GiftCardMailer#send' do
          expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card).and_return(double(deliver_later: true))
          expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card_2).and_return(double(deliver_later: true))
          subject
          expect(gift_card.reload.sent_at).to be_present
        end
      end

      context 'send_email_at is in the past' do
        let(:send_email_at) { 2.days.ago }

        it 'calls GiftCardMailer#send' do
          expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card).and_return(double(deliver_later: true))
          expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card_2).and_return(double(deliver_later: true))
          subject
          expect(gift_card.reload.sent_at).to be_present
        end
      end

      context 'send_email_at is in the future' do
        let(:send_email_at) { 2.days.from_now }

        it 'does not call GiftCardMailer#send' do
          expect(Spree::GiftCardMailer).not_to receive(:gift_card_email)
          subject
          expect(gift_card.reload.sent_at).not_to be_present
        end
      end
    end

    context 'no gift cards' do
      let(:order) { create(:order_with_line_items) }

      it 'does not call GiftCardMailer#send' do
        expect(Spree::GiftCardMailer).not_to receive(:gift_card_email)
        subject
      end
    end
  end

  context "gift card" do
    shared_examples "check total gift card from payments" do
      context "with valid payments" do
        let(:order) { payment.order }
        let!(:payment) { create(:gift_card_payment) }
        let!(:second_payment) { create(:gift_card_payment, order:) }

        subject { order }

        it "returns the sum of the payment amounts" do
          expect(subject.total_applicable_gift_card).to eq(payment.amount + second_payment.amount)
        end
      end

      context "without valid payments" do
        let(:order) { create(:order) }

        subject { order }

        it "returns 0" do
          expect(subject.total_applicable_gift_card).to be_zero
        end
      end
    end

    describe "#add_gift_card_payments" do
      let(:order_total) { 500.00 }

      before do
        create(:gift_card_payment_method)
        order.update(gift_card_codes: gift_card_codes)
      end

      subject { order.add_gift_card_payments }

      context "no gift card codes provided" do
        let(:gift_card_codes) { [] }
        let(:order) { create(:order, total: order_total) }


        context "there is a credit card payment" do
          # let!(:cc_payment) { create(:payment, order:, amount: order_total) }

          before do
            create(:payment, order:, amount: order_total)
            # callbacks recalculate total based on line items
            # this ensures the total is what we expect
            order.update(total: order_total)
            subject
            order.reload
          end

          it "charges the outstanding balance to the credit card" do
            expect(order.errors.messages).to be_empty
            expect(order.payments.count).to eq 1
            expect(order.payments.first.source).to be_a(Spree::CreditCard)
            expect(order.payments.first.amount).to eq order_total
          end
        end
      end

      context 'there is gift card in another currency' do
        let(:order) { create(:order_with_totals, user:, line_items_price: order_total).tap(&:recalculate) }
        let!(:virtual_gift_card_usd) { create(:redeemable_virtual_gift_card, amount: 1, currency: 'USD') }
        let!(:virtual_gift_card_gbp) { create(:redeemable_virtual_gift_card, amount: 1, currency: 'GBP') }
        let(:user) { create(:user) }
        let(:gift_card_codes) { [virtual_gift_card_usd.redemption_code, virtual_gift_card_gbp.redemption_code] }

        it 'only adds the credit in the matching currency' do
          order.update(gift_card_codes: [virtual_gift_card_usd.redemption_code, virtual_gift_card_gbp.redemption_code])
          expect {
            order.add_gift_card_payments
          }.to change {
            order.payments.count
          }.by(1)

          applied_gift_cards = order.payments.gift_cards.map(&:source)
          expect(applied_gift_cards).to match_array([virtual_gift_card_usd])
        end
      end

      context "there is enough amount on gift card to pay for the entire order" do
        let(:virtual_gift_card) { create(:redeemable_virtual_gift_card, amount: order_total) }
        let(:order) { create(:order_with_totals, user:, line_items_price: order_total).tap(&:recalculate) }
        let(:user) { create(:user) }
        let(:gift_card_codes) { [virtual_gift_card.redemption_code] }

        context "there are no other payments" do
          before do
            subject
            order.reload
          end

          it "creates a gift card payment for the full amount" do
            expect(order.errors.messages).to be_empty
            expect(order.payments.count).to eq 1
            expect(order.payments.first).to be_gift_card
            expect(order.payments.first.amount).to eq order_total
          end
        end

        context "there is a credit card payment" do
          it "invalidates the credit card payment" do
            cc_payment = create(:payment, order:)
            expect { subject }.to change { cc_payment.reload.state }.to 'invalid'
          end
        end
      end

      context "the available gift card is not enough to pay for the entire order" do
        let(:order_total) { 500 }
        let(:gift_card_total) { order_total - 100 }
        let(:virtual_gift_card) { create(:redeemable_virtual_gift_card, amount: gift_card_total) }
        let(:order) { create(:order_with_totals, line_items_price: order_total).tap(&:recalculate) }
        let(:gift_card_codes) { [virtual_gift_card.redemption_code] }

        context "there are no other payments" do
          it "adds an error to the model" do
            expect(subject).to be false
            expect(order.errors.full_messages).to include(I18n.t('spree.virtual_gift_card.errors.unable_to_fund'))
          end
        end

        context "there is a completed gift card payment" do
          it "successfully creates the gift card payments" do
            create(:payment, order:, state: "completed", amount: 100)

            expect { subject }.to change { order.payments.count }.from(1).to(2)
            expect(order.errors).to be_empty
          end
        end

        context "there is a credit card payment" do
          before do
            create(:payment, order:, state: "checkout", amount: 100)

            subject
          end

          it "charges the outstanding balance to the credit card" do
            expect(order.errors.messages).to be_empty
            expect(order.payments.count).to eq 2
            expect(order.payments.first.source).to be_a(Spree::CreditCard)
            expect(order.payments.first.amount).to eq 100
          end

          # see associated comment in order_decorator#add_gift_card_payments
          context "the gift card is already in the pending state" do
            before do
              order.payments.gift_cards.last.authorize!
              order.add_gift_card_payments
            end

            it "charges the outstanding balance to the credit card" do
              expect(order.errors.messages).to be_empty
              expect(order.payments.count).to eq 2
              expect(order.payments.first.source).to be_a(Spree::CreditCard)
              expect(order.payments.first.amount).to eq 100
            end
          end
        end
      end

      context "there are multiple gift cards" do
        context "they have been added sequentially" do
          let(:amount_difference) { 100 }
          let!(:second_virtual_gift_card) { create(:redeemable_virtual_gift_card, amount: order_total) }
          let!(:first_virtual_gift_card) { create(:redeemable_virtual_gift_card, amount: (order_total - amount_difference)) }
          let(:order) { create(:order_with_totals, line_items_price: order_total).tap(&:recalculate) }
          let(:gift_card_codes) { [first_virtual_gift_card.redemption_code, second_virtual_gift_card.redemption_code] }

          before do
            subject
            order.reload
          end

          it "uses the second gift card before the first" do
            first_payment = order.payments.detect{ |x| x.source == first_virtual_gift_card }
            second_payment = order.payments.detect{ |x| x.source == second_virtual_gift_card }

            expect(order.payments.size).to eq 2
            expect(first_payment.source).to eq first_virtual_gift_card
            expect(second_payment.source).to eq second_virtual_gift_card
            expect(first_payment.amount).to eq(order_total - amount_difference)
            expect(second_payment.amount).to eq(amount_difference)
          end
        end
      end
    end

    describe "#covered_by_gift_card" do
      let(:gift_card_codes) { [] }
      let(:order) { create(:order_with_line_items, gift_card_codes: gift_card_codes) }

      subject do
        order.covered_by_gift_card
      end

      context "order doesn't have any associated gift card codes" do
        it { is_expected.to eq(false) }
      end

      context "order has gift card codes" do
        let(:gift_card_codes) { [virtual_gift_card.redemption_code] }

        context "user has enough gift card amount to pay for the order" do
          let!(:virtual_gift_card) { create(:redeemable_virtual_gift_card, amount: 1000) }

          it { is_expected.to eq(true) }
        end

        context "user does not have enough gift card amount to pay for the order" do
          let!(:virtual_gift_card) { create(:redeemable_virtual_gift_card, amount: 1) }

          it { is_expected.to eq(false) }
        end
      end
    end

    describe "#total_applicable_gift_card" do
      context "order is in the confirm state" do
        before { order.update(state: 'confirm') }

        include_examples "check total gift card from payments"
      end

      context "order is completed" do
        before { order.update(state: 'complete') }

        include_examples "check total gift card from payments"
      end

      context "order is in any state other than confirm or complete" do
        context "the order has gift cards" do
          let(:virtual_gift_card) { create(:redeemable_virtual_gift_card) }
          let(:order) { create(:order, gift_card_codes: [virtual_gift_card.redemption_code]) }

          subject { order }

          context "the gift card amount is more than the order total" do
            let(:order_total) { virtual_gift_card.amount - 1 }

            before { order.update(total: order_total) }

            it "returns the order total" do
              expect(subject.total_applicable_gift_card).to eq order_total
            end
          end

          context "the gift card is less than the order total" do
            let(:order_total) { virtual_gift_card.amount * 10 }

            before { order.update(total: order_total) }

            it "returns the gift card amount" do
              expect(subject.total_applicable_gift_card).to eq virtual_gift_card.amount
            end
          end
        end

        context "the order doesn't have gift card codes associated" do
          let(:order) { create(:order) }

          subject { order }

          it "returns 0" do
            expect(subject.total_applicable_gift_card).to be_zero
          end
        end
      end
    end
  end
end
