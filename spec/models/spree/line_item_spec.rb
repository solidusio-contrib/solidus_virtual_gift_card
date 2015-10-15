require 'spec_helper'

describe Spree::LineItem do
  describe "#redemption_codes" do
    let(:line_item) { create(:line_item, quantity: 2) }
    let!(:gift_card) { create(:redeemable_virtual_gift_card, line_item: line_item) }
    let!(:gift_card_2) { create(:redeemable_virtual_gift_card, line_item: line_item) }
    let(:subject) { line_item.redemption_codes }

    it 'has the correct number of redemption codes and keys' do
      expect(subject.size).to eq line_item.quantity
    end

    it 'contains a redemption_code' do
      expect(subject.first).to have_key :redemption_code
    end

    it 'formats the redemption_code' do
      expect(subject.first).to have_value gift_card.formatted_redemption_code
    end

    it 'contains an amount' do
      expect(subject.first).to have_key :amount
    end

    it 'formats the amount' do
      expect(subject.first).to have_value gift_card.formatted_amount
    end
  end
end
