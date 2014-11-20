class Spree::GiftCardMailer < Spree::BaseMailer
  def gift_card_email(gift_card)
    @gift_card = gift_card.respond_to?(:id) ? gift_card : Spree::VirtualGiftCard.find(gift_card)
    @order = @gift_card.line_item.order
    subject = "#{Spree::Config[:site_name]} #{Spree.t('gift_card_mailer.gift_card_email.subject')}"
    mail(to: @order.email, from: from_address, subject: subject)
  end
end