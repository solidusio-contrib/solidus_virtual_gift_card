require 'spec_helper'

describe Spree::Order do
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
