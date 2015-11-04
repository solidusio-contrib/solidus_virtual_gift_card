require 'spec_helper'

describe "solidus_virtual_gift_card:send_current_emails" do

  let(:task) { Rake::Task['solidus_virtual_gift_card:send_current_emails'] }
  let(:purchaser) {create(:user)}

  before do
    Rails.application.load_tasks
    task.reenable
  end

  subject { task.invoke }

  context "with gift card sent today" do
    it "sends emails to be sent today" do
      gift_card = Spree::VirtualGiftCard.create!(amount: 50, send_email_at: Date.today, redeemable: true, purchaser: purchaser)
      expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card).and_return(double(deliver_later: true))
      subject
    end

    it "does not send unredeemable giftcards" do
      gift_card = Spree::VirtualGiftCard.create!(amount: 50, send_email_at: Date.today)
      expect(Spree::GiftCardMailer).to_not receive(:gift_card_email).with(gift_card)
      subject
    end
  end

  context "with gift card already sent today" do
    it "sends emails to be sent today" do
      Spree::VirtualGiftCard.create!(amount: 50, send_email_at: Date.today, sent_at: DateTime.now, redeemable: true, purchaser: purchaser)
      expect(Spree::GiftCardMailer).to_not receive(:gift_card_email)
      subject
    end
  end

  context "with gift cards sent in the future" do
    it "does not sends emails" do
      Spree::VirtualGiftCard.create!(amount: 50, send_email_at: 10.days.from_now.to_date, redeemable: true, purchaser: purchaser)
      expect(Spree::GiftCardMailer).to_not receive(:gift_card_email)
      subject
    end
  end

  context "with gift cards sent in the past" do
    it "does not sends emails" do
      Spree::VirtualGiftCard.create!(amount: 50, send_email_at: 1.days.ago, sent_at: 1.days.ago.to_date, redeemable: true, purchaser: purchaser)
      expect(Spree::GiftCardMailer).to_not receive(:gift_card_email)
      subject
    end
  end

  context "with gift cards not specified" do
    it "does not sends emails" do
      Spree::VirtualGiftCard.create!(amount: 50, send_email_at: nil)
      expect(Spree::GiftCardMailer).to_not receive(:gift_card_email)
      subject
    end
  end
end
