namespace :solidus_virtual_gift_card do
  desc "Send todays gift card emails"
  task :send_current_emails => :environment do
    Spree::VirtualGiftCard.where(send_email_at: Date.today, sent_at: nil, redeemable: true).find_each do |gift_card|
      gift_card.send_email
    end
  end
end
