require 'spec_helper'

describe Spree::Order do
  describe "#finalize!" do
    context "the order contains gift cards and transitions to complete" do
      let(:gift_card) { create(:virtual_gift_card) }
      let(:order) { create(:order_with_line_items, state: 'complete', line_items: [gift_card.line_item]) }

      subject { order.finalize! }

      it "makes the gift card redeemable" do
        subject
        expect(gift_card.reload.redeemable).to be true
        expect(gift_card.reload.redemption_code).to be_present
      end
    end
  end

  describe "#send_gift_card_emails" do
    subject { order.send_gift_card_emails }

    context "the order has gift cards" do
      let(:gift_card) { create(:virtual_gift_card, send_email_at: send_email_at) }
      let(:line_item) { gift_card.line_item }
      let(:gift_card_2) { create(:virtual_gift_card, line_item: line_item, send_email_at: send_email_at) }
      let(:order) { gift_card.line_item.order }

      context "send_email_at is not set" do
        let(:send_email_at) { nil }
        it "should call GiftCardMailer#send" do
          expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card).and_return(double(deliver_later: true))
          expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card_2).and_return(double(deliver_later: true))
          subject
          expect(gift_card.reload.sent_at).to be_present
        end
      end

      context "send_email_at is in the past" do
        let(:send_email_at) { 2.days.ago }
        it "should call GiftCardMailer#send" do
          expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card).and_return(double(deliver_later: true))
          expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card_2).and_return(double(deliver_later: true))
          subject
          expect(gift_card.reload.sent_at).to be_present
        end
      end

      context "send_email_at is in the future" do
        let(:send_email_at) { 2.days.from_now }
        it "does not call GiftCardMailer#send" do
          expect(Spree::GiftCardMailer).to_not receive(:gift_card_email)
          subject
          expect(gift_card.reload.sent_at).to_not be_present
        end
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
end
