require 'spec_helper'

describe Spree::GiftCardMailer, type: :mailer do
  context '#gift_card_email' do
    let(:gift_card) { create(:redeemable_virtual_gift_card) }

    subject { Spree::GiftCardMailer.gift_card_email(gift_card) }

    context "the recipient email is blank" do
      before do
        gift_card.update_attributes!(recipient_email: "")
        gift_card.line_item.order.update_attributes!(email: "gift_card_tester@example.com")
      end

      it "uses the email associated with the order" do
        expect(subject.to).to contain_exactly('gift_card_tester@example.com')
      end
    end
  end
end
