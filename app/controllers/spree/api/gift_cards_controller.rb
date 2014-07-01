class Spree::Api::GiftCardsController < Spree::Api::BaseController

  def redeem
    redemption_code = Spree::RedemptionCodeGenerator.format_redemption_code_for_lookup(gift_card_params)
    @gift_card = Spree::VirtualGiftCard.active_by_redemption_code(redemption_code)

    if !@gift_card
      render status: :not_found, json: redeem_fail_response
    elsif @gift_card.redeem(@current_api_user)
      render status: :created, json: {}
    else
      render status: 422, json: redeem_fail_response
    end
  end

  private

  def gift_card_params
    params.require(:redemption_code)
  end

  def redeem_fail_response
   {
      error_message: "#{Spree.t('admin.gift_cards.errors.not_found')}. #{Spree.t('admin.gift_cards.errors.please_try_again')}"
   }
 end
end
