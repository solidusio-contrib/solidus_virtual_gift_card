require 'spec_helper'

describe Spree::Order do
  describe "#finalize!" do
    context "the order contains gift cards and transitions to complete" do
      let(:gift_card) { create(:virtual_gift_card) }
      let(:order) { create(:order_with_line_items, state: 'complete', line_items: [gift_card.line_item]) }

      subject { order.finalize! }

      it "activates the gift card" do
        subject
        expect(gift_card.reload.redeemable).to be true
      end
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
end
