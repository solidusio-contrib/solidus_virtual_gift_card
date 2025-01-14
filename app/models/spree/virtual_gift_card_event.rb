class Spree::VirtualGiftCardEvent < ApplicationRecord
  include Spree::SoftDeletable

  belongs_to :virtual_gift_card, optional: true
  belongs_to :originator, polymorphic: true, optional: true

  NON_EXPOSED_ACTIONS = [Spree::VirtualGiftCard::ELIGIBLE_ACTION, Spree::VirtualGiftCard::AUTHORIZE_ACTION]

  scope :exposed_events, -> { exposable_actions.not_invalidated }
  scope :exposable_actions, -> { where.not(action: NON_EXPOSED_ACTIONS) }
  scope :not_invalidated, -> { joins(:virtual_gift_card).where(spree_virtual_gift_cards: { deactivated_at: nil }) }
  scope :chronological, -> { order(:created_at) }
  scope :reverse_chronological, -> { order(created_at: :desc) }

  delegate :currency, to: :virtual_gift_card

  def capture_action?
    action == Spree::VirtualGiftCard::CAPTURE_ACTION
  end

  def authorization_action?
    action == Spree::VirtualGiftCard::AUTHORIZE_ACTION
  end

  def display_amount
    Spree::Money.new(amount, { currency: })
  end

  def display_user_total_amount
    Spree::Money.new(user_total_amount, { currency: })
  end

  def display_remaining_amount
    Spree::Money.new(amount_remaining, { currency: })
  end

  def display_event_date
    I18n.l(created_at.to_date, format: :long)
  end

  def display_action
    return if NON_EXPOSED_ACTIONS.include?(action)
    I18n.t("spree.virtual_gift_card.display_action.#{action}")
  end

  def order
    Spree::Payment.find_by(response_code: authorization_code).try(:order)
  end
end
