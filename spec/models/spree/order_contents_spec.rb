# frozen_string_literal: true

require 'spec_helper'

describe Spree::OrderContents do
  let(:order) { create(:order) }
  let(:variant) { create(:variant) }
  let(:order_contents) { described_class.new(order) }

  let(:recipient_name) { 'Ron Weasly' }
  let(:recipient_email) { 'ron@weasly.com' }
  let(:purchaser_name) { 'Harry Potter' }
  let(:gift_message) { 'Thought you could use some trousers, mate' }
  let(:send_email_at) { 2.days.from_now }
  let(:options) do
    {
      'gift_card_details' => {
        'recipient_name' => recipient_name,
        'recipient_email' => recipient_email,
        'purchaser_name' => purchaser_name,
        'gift_message' => gift_message,
        'send_email_at' => send_email_at
      }
    }
  end
  let(:quantity) { 1 }

  describe '#add' do
    subject { order_contents.add(variant, quantity, options) }

    it 'creates a line item' do
      expect { subject }.to change { Spree::LineItem.count }.by(1)
    end

    context 'with a gift card product' do
      before { variant.product.update(gift_card: true) }

      it 'creates a line item' do
        expect { subject }.to change { Spree::LineItem.count }.by(1)
      end

      context 'with a single gift card' do
        it 'creates a gift card' do
          expect { subject }.to change { Spree::VirtualGiftCard.count }.by(1)
          gift_card = Spree::VirtualGiftCard.last
          expect(gift_card.recipient_name).to eq(recipient_name)
          expect(gift_card.recipient_email).to eq(recipient_email)
          expect(gift_card.purchaser_name).to eq(purchaser_name)
          expect(gift_card.gift_message).to eq(gift_message)
          expect(gift_card.send_email_at).to eq(send_email_at.to_date)
        end

        describe '#format_date' do
          context 'without send_email_at' do
            let(:send_email_at) { nil }

            it 'sets to current date' do
              subject
              gift_card = Spree::VirtualGiftCard.last
              expect(gift_card.send_email_at).to eq(Date.today)
            end
          end

          context 'with invalid date' do
            let(:send_email_at) { '12/14/2020' }

            it 'errors' do
              expect{ subject }.to raise_error Spree::GiftCards::GiftCardDateFormatError
            end
          end
        end
      end

      context 'with multiple gift cards' do
        let(:quantity) { 2 }

        it 'creates two gift cards' do
          expect { subject }.to change { Spree::VirtualGiftCard.count }.by(2)
        end
      end

      context 'adding a gift card with an existing line item' do
        context 'when the gift card properties match' do
          before { @line_item = order_contents.add(variant, quantity, options) }

          it 'adds to the existing gift card' do
            expect(order.line_items.count).to be(1)
            new_line_item = subject
            expect(order.reload.line_items.count).to be(1)
            expect(@line_item.reload.gift_cards.count).to be(2)
          end
        end

        context 'when the gift card properties are different' do
          let(:recipient_name2)  { 'Severus Snape' }
          let(:recipient_email2) { 'wingardium@leviosa.com' }
          let(:purchaser_name2)  { 'Dumbledore' }
          let(:options2) do
            {
              'gift_card_details' => {
                'recipient_name' => recipient_name2,
                'recipient_email' => recipient_email2,
                'purchaser_name' => purchaser_name2,
                'gift_message' => gift_message,
                'send_email_at' => send_email_at
              }
            }
          end

          before { @line_item = order_contents.add(variant, quantity, options2) }

          it 'creates a new line item with a gift card' do
            expect(order.line_items.count).to be(1)
            new_line_item = subject
            expect(@line_item.id).not_to eq new_line_item.id
            expect(order.reload.line_items.count).to be(2)
            expect(new_line_item.gift_cards.count).to be(1)
          end
        end
      end
    end

    context 'with a non gift card product' do
      it 'does not create a gift card' do
        expect { subject }.not_to change { Spree::VirtualGiftCard.count }
      end
    end
  end

  describe '#remove' do
    subject { order_contents.remove(variant, quantity, options) }

    context 'for a non-gift-card product' do
      before { order_contents.add(variant, quantity, options) }

      it 'deletes a line item' do
        expect { subject }.to change { Spree::LineItem.count }.by(-1)
      end
    end

    context 'with a gift card product' do
      before do
        variant.product.update(gift_card: true)
      end

      context 'with a single gift card' do
        before do
          order_contents.add(variant, quantity, options)
        end

        it 'deletes a line item' do
          expect { subject }.to change { Spree::LineItem.count }.by(-1)
        end

        it 'deletes a gift card' do
          expect { subject }.to change { Spree::VirtualGiftCard.count }.by(-1)
        end
      end

      context 'with multiple gift cards' do
        let(:quantity) { 2 }

        before do
          order_contents.add(variant, quantity, options)
        end

        it 'deletes two gift cards' do
          expect { subject }.to change { Spree::VirtualGiftCard.count }.by(-2)
        end
      end

      context 'with two gift card line items with identical variants' do
        let(:recipient_name2)  { 'Severus Snape' }
        let(:recipient_email2) { 'wingardium@leviosa.com' }
        let(:purchaser_name2)  { 'Dumbledore' }
        let(:options2) do
          {
            'gift_card_details' => {
              'recipient_name' => recipient_name2,
              'recipient_email' => recipient_email2,
              'purchaser_name' => purchaser_name2,
              'gift_message' => gift_message,
              'send_email_at' => send_email_at
            }
          }
        end

        before do
          @line_item = order_contents.add(variant, quantity, options)
          @line_item2 = order_contents.add(variant, quantity, options2)
        end

        context 'removing the first line item' do
          it 'removes the correct line item' do
            expect(order.line_items.count).to be(2)
            subject
            expect(order.reload.line_items.count).to be(1)
            expect(order.line_items).not_to include(@line_item)
          end
        end

        context 'removing the second line item' do
          subject { order_contents.remove(variant, quantity, options2) }

          it 'removes the correct line item' do
            expect(order.line_items.count).to be(2)
            subject
            expect(order.reload.line_items.count).to be(1)
            expect(order.line_items).not_to include(@line_item2)
          end
        end
      end

      context 'when no gift card details are supplied' do
        subject { order_contents.remove(variant, quantity) }

        before do
          order_contents.add(variant, quantity, options)
        end

        it 'removes the line item with the correct variant' do
          expect { subject }.to change { Spree::LineItem.count }.by(-1)
        end

        it 'removes the gift card' do
          expect { subject }.to change { Spree::VirtualGiftCard.count }.by(-1)
        end
      end
    end

    describe '#update_cart' do
      subject { order_contents.update_cart(update_params) }

      let(:update_params) do
        {
          line_items_attributes: {
            '0' => { id: @line_item.id, quantity: quantity, options: {} }
          }
        }
      end

      context 'for a gift card line item' do
        before do
          variant.product.update(gift_card: true)
          @line_item = order_contents.add(variant, 2, options)
        end

        context 'line item is being updated to a higher quantity' do
          let(:quantity) { '4' }

          it 'creates new gift cards' do
            expect { subject }.to change { Spree::VirtualGiftCard.count }.by(2)
          end
        end

        context 'line item is being updated to a lower quantity' do
          context 'one lower' do
            let(:quantity) { '1' }

            it 'destroys gift cards' do
              expect { subject }.to change { Spree::VirtualGiftCard.count }.by(-1)
            end
          end

          context 'multiple lower' do
            let(:quantity) { '0' }

            it 'destroys gift cards' do
              expect { subject }.to change { Spree::VirtualGiftCard.count }.by(-2)
            end
          end
        end
      end
    end
  end
end
