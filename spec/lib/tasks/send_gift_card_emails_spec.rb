require 'spec_helper'

describe "solidus_virtual_gift_card:send_current_emails" do

  let(:task) { Rake::Task['solidus_virtual_gift_card:send_current_emails'] }

  before do
    Rails.application.load_tasks
    task.reenable
  end

  subject { task.invoke }

  context "with gift card sent today" do
    it "sends emails to be sent today" do
      gift_card = Spree::VirtualGiftCard.create!(amount: 50, send_email_at: DateTime.now)
      expect(Spree::GiftCardMailer).to receive(:gift_card_email).with(gift_card).and_return(double(deliver: true))
      subject
    end
  end

  context "with gift card already sent today" do
    it "sends emails to be sent today" do
      Spree::VirtualGiftCard.create!(amount: 50, send_email_at: DateTime.now, sent_at: DateTime.now)
      expect(Spree::GiftCardMailer).to_not receive(:gift_card_email)
      subject
    end
  end

  context "with gift cards sent in the future" do
    it "does not sends emails" do
      Spree::VirtualGiftCard.create!(amount: 50, send_email_at: 10.days.from_now)
      expect(Spree::GiftCardMailer).to_not receive(:gift_card_email)
      subject
    end
  end

  context "with gift cards sent in the past" do
    it "does not sends emails" do
      Spree::VirtualGiftCard.create!(amount: 50, send_email_at: 1.days.ago, sent_at: 1.days.ago)
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
