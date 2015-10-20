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
      "gift_card_details" => {
        "recipient_name" => recipient_name,
        "recipient_email" => recipient_email,
        "purchaser_name" => purchaser_name,
        "gift_message" => gift_message,
      }
    }
  end
  let(:quantity) { 1 }

  describe "#add" do
    subject { order_contents.add(variant, quantity, options) }

    it "creates a line item" do
      expect { subject }.to change { Spree::LineItem.count }.by(1)
    end

    context "with a gift card product" do
      before { variant.product.update_attributes(gift_card: true) }

      it "creates a line item" do
        expect { subject }.to change { Spree::LineItem.count }.by(1)
      end

      context "with a single gift card" do
        it "creates a gift card" do
          expect { subject }.to change { Spree::VirtualGiftCard.count }.by(1)
          gift_card = Spree::VirtualGiftCard.last
          expect(gift_card.recipient_name).to eq(recipient_name)
          expect(gift_card.recipient_email).to eq(recipient_email)
          expect(gift_card.purchaser_name).to eq(purchaser_name)
          expect(gift_card.gift_message).to eq(gift_message)
        end
      end

      context "with multiple gift cards" do
        let(:quantity) { 2 }

        it "creates two gift cards" do
          expect { subject }.to change { Spree::VirtualGiftCard.count }.by(2)
        end
      end
    end


    context "with a non gift card product" do
      it "does not create a gift card" do
        expect { subject }.to_not change { Spree::VirtualGiftCard.count }
      end
    end
  end

  describe "#remove" do
    subject { order_contents.remove(variant, quantity) }

    context "for a non-gift-card product" do
      before { order_contents.add(variant, quantity, options) }

      it "deletes a line item" do
        expect { subject }.to change { Spree::LineItem.count }.by(-1)
      end
    end

    context "with a gift card product" do
      before do
        variant.product.update_attributes(gift_card: true)
        order_contents.add(variant, quantity, options)
      end

      context "with a single gift card" do
        it "deletes a line item" do
          expect { subject }.to change { Spree::LineItem.count }.by(-1)
        end

        it "deletes a gift card" do
          expect { subject }.to change { Spree::VirtualGiftCard.count }.by(-1)
        end
      end

      context "with multiple gift cards" do
        let(:quantity) { 2 }

        it "deletes two gift cards" do
          expect { subject }.to change { Spree::VirtualGiftCard.count }.by(-2)
        end
      end
    end

    describe "#update_cart" do
      subject { order_contents.update_cart(update_params) }

      let(:update_params) do
        {
          line_items_attributes: { id: @line_item.id, quantity: quantity, options: {}}
        }
      end

      context "for a gift card line item" do
        before do
          variant.product.update_attributes(gift_card: true)
          @line_item = order_contents.add(variant, 2, options)
        end

        context "line item is being updated to a higher quantity" do
          let(:quantity) { "4" }

          it "creates new gift cards" do
            expect { subject }.to change { Spree::VirtualGiftCard.count }.by(2)
          end
        end

        context "line item is being updated to a lower quantity" do
          context "one lower" do
            let(:quantity) { "1" }

            it "destroys gift cards" do
              expect { subject }.to change { Spree::VirtualGiftCard.count }.by(-1)
            end
          end

          context "multiple lower" do
            let(:quantity) { "0" }

            it "destroys gift cards" do
              expect { subject }.to change { Spree::VirtualGiftCard.count }.by(-2)
            end
          end
        end
      end
    end
  end
end
