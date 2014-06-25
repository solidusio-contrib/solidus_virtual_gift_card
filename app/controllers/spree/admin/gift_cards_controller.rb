class Spree::Admin::GiftCardsController < Spree::Admin::BaseController
  before_filter :load_gift_card, only: [:show]

  def index
  end

  def show
  end

  private

  def load_gift_card
    redemption_code = format_redemption_code(params[:id])
    @gift_cards = Spree::VirtualGiftCard.where(redemption_code: redemption_code)

    if @gift_cards.empty?
      flash[:error] = Spree.t('admin.gift_cards.errors.not_found')
      redirect_to(admin_gift_cards_path)
    end
  end

  def format_redemption_code(redemption_code)
    redemption_code.delete('-').scan(/.{1,4}/).join('-')
  end
end
