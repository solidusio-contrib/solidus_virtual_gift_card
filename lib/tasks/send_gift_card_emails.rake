namespace :solidus_virtual_gift_card do
  desc "Send todays gift card emails"
  task :send_current_emails => :environment do
    Spree::VirtualGiftCard.where(send_email_at: DateTime.now.beginning_of_day..DateTime.now.end_of_day, sent_at: nil).each do |gift_card|
      Spree::GiftCardMailer.gift_card_email(gift_card).deliver
      gift_card.touch(:sent_at)
    end
  end
end
