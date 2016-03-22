require 'spec_helper'

describe Spree::LineItem do
  describe "#redemption_codes" do
    let(:line_item) { create(:line_item, quantity: 2) }
    let!(:gift_card) { create(:virtual_gift_card, line_item: line_item) }
    let!(:gift_card_2) { create(:virtual_gift_card, line_item: line_item) }
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

  describe "#gift_card_details" do
    let(:line_item) { create(:line_item, quantity: 2) }
    let!(:gift_card) { create(:redeemable_virtual_gift_card, line_item: line_item) }
    let!(:gift_card_2) { create(:redeemable_virtual_gift_card, line_item: line_item) }
    let(:subject) { line_item.gift_card_details }

    it 'contains all gift cards on the line item' do
      expect(subject.size).to eq line_item.quantity
    end

    it 'contains the correct keys and values' do
      gift_card_details = subject.detect{|x| x[:redemption_code] == gift_card.formatted_redemption_code }
      expect(gift_card_details[:amount]).to eq gift_card.formatted_amount
      expect(gift_card_details[:redemption_code]).to eq gift_card.formatted_redemption_code
      expect(gift_card_details[:recipient_email]).to eq gift_card.recipient_email
      expect(gift_card_details[:recipient_name]).to eq gift_card.recipient_name
      expect(gift_card_details[:purchaser_name]).to eq gift_card.purchaser_name
      expect(gift_card_details[:gift_message]).to eq gift_card.gift_message
    end
  end
end
