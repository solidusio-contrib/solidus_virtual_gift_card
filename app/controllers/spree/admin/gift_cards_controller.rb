# frozen_string_literal: true

class Spree::Admin::GiftCardsController < Spree::Admin::BaseController
  before_action :load_user, only: [:lookup, :redeem]
  before_action :load_gift_card_for_redemption, only: [:redeem]
  before_action :load_gift_card_by_id, only: [:edit, :update, :send_email, :deactivate]
  before_action :load_order, only: [:edit, :update, :deactivate]

  def index
    @search = Spree::VirtualGiftCard.purchased.ransack(params[:q])
    @gift_cards = @search.result.page(params[:page]).per(params[:per_page])
  end

  def edit; end

  def lookup; end

  def update
    if @gift_card.update(gift_card_params)
      flash[:success] = I18n.t('spree.admin.gift_cards.gift_card_updated')
      redirect_to edit_admin_order_path(@order)
    else
      flash[:error] = @gift_card.errors.full_messages.join(', ')
      redirect_to :back
    end
  end

  def redeem
    if @gift_card.redeem(@user)
      flash[:success] = I18n.t('spree.admin.gift_cards.redeemed_gift_card')
      redirect_to admin_user_store_credits_path(@user)
    else
      flash[:error] = I18n.t('spree.admin.gift_cards.errors.unable_to_redeem_gift_card')
      render :lookup
    end
  end

  def deactivate
    if @gift_card.deactivate
      flash[:success] = I18n.t('spree.admin.gift_cards.deactivated_gift_card')
      redirect_to edit_admin_order_path(@order)
    else
      flash[:error] = @gift_card.errors.full_messages.join(', ').presence || I18n.t('spree.admin.gift_cards.errors.unable_to_reimburse_gift_card')
      redirect_to edit_admin_order_gift_card_path(@order, @gift_card)
    end
  rescue Spree::Reimbursement::IncompleteReimbursementError
    flash[:error] = I18n.t('spree.admin.gift_cards.errors.unable_to_reimburse_gift_card')
    redirect_to edit_admin_order_gift_card_path(@order, @gift_card)
  end

  def send_email
    @gift_card.send_email
    redirect_to :back
  end

  private

  def load_gift_card_for_redemption
    redemption_code = Spree::RedemptionCodeGenerator.format_redemption_code_for_lookup(params[:gift_card][:redemption_code])
    @gift_card = Spree::VirtualGiftCard.active_by_redemption_code(redemption_code)

    if @gift_card.blank?
      flash[:error] = I18n.t('spree.admin.gift_cards.errors.not_found')
      render :lookup
    end
  end

  def load_gift_card_by_id
    @gift_card = Spree::VirtualGiftCard.find_by(id: params[:id])
  end

  def load_order
    @order = Spree::Order.find_by(number: params[:order_id])
  end

  def load_user
    @user = Spree.user_class.find(params[:user_id])
  end

  def gift_card_params
    params.require(:virtual_gift_card).permit(:recipient_name, :recipient_email, :purchaser_name, :gift_message, :send_email_at)
  end

  def model_class
    Spree::VirtualGiftCard
  end
end
