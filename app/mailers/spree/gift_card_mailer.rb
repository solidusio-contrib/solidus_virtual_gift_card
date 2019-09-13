class Spree::GiftCardMailer < Spree::BaseMailer
  def gift_card_email(gift_card)
    @gift_card = gift_card.respond_to?(:id) ? gift_card : Spree::VirtualGiftCard.find(gift_card)
    @order = @gift_card.line_item.order

    store = @order.store
    send_to_address = @gift_card.recipient_email.presence || @order.email
    subject = "#{store} #{Spree.t('gift_card_mailer.gift_card_email.subject')}"

    mail(to: send_to_address, from: from_address(store), subject: subject)
  end
end
