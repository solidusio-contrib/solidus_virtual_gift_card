require 'spec_helper'

describe Spree::OrderContents do
  let(:order) { create(:order) }
  let(:variant) { create(:variant) }
  let(:order_contents) { Spree::OrderContents.new(order) }

  let(:recipient_name) { "Ron Weasly" }
  let(:recipient_email) { "ron@weasly.com" }
  let(:purchaser_name) { "Harry Potter" }
  let(:gift_message) { "Thought you could use some trousers, mate" }
  let(:options) do
    {
      gift_card_details: {
        recipient_name: recipient_name,
        recipient_email: recipient_email,
        purchaser_name: purchaser_name,
        gift_message: gift_message,
      }
    }
  end

  subject { order_contents.add(variant, 1, options) }

  describe "#add" do
    it "creates a line item" do
      expect { subject }.to change { Spree::LineItem.count }.by(1)
    end

    context "with a gift card product" do
      before { variant.product.update_attributes(gift_card: true) }

      it "creates a giftcard" do
        expect { subject }.to change { Spree::VirtualGiftCard.count }.by(1)
        gift_card = Spree::VirtualGiftCard.last
        expect(gift_card.recipient_name).to eq(recipient_name)
        expect(gift_card.recipient_email).to eq(recipient_email)
        expect(gift_card.purchaser_name).to eq(purchaser_name)
        expect(gift_card.gift_message).to eq(gift_message)
      end
    end

    context "with a non gift card product" do
      it "does not create a giftcard" do
        expect { subject }.to_not change { Spree::VirtualGiftCard.count }
      end
    end
  end
end
