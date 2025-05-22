# frozen_string_literal: true

require "spec_helper"

describe "Gift Cards", type: :feature do
  stub_authorization!

  let(:gift_card) { create(:redeemable_virtual_gift_card) }
  let(:product) { gift_card.line_item.product }
  let!(:order) do
    create(:order_ready_to_ship,
           number: "R100",
           state: "complete",
           line_items: [gift_card.line_item])
  end
  let(:admin_user) { create(:admin_user) }

  before do
    allow_any_instance_of(Spree::Admin::BaseController).to receive(:spree_current_user).and_return(admin_user)
    product.update_attribute(:gift_card, true)
  end

  describe "edit gift card" do
    let(:new_recipient_name) { "Heidi" }
    let(:new_recipient_email) { "heidi@gmail.com" }
    let(:new_purchaser_name) { "Neerali" }
    let(:new_gift_message) { "Sweaters!" }

    it "can edit recipient information and send email date" do
      visit spree.edit_admin_order_path(order)

      within('fieldset[data-hook="gift-card"]') do
        click_link("Edit")
      end

      fill_in "virtual_gift_card_recipient_name", with: new_recipient_name
      fill_in "virtual_gift_card_recipient_email", with: new_recipient_email
      fill_in "virtual_gift_card_purchaser_name", with: new_purchaser_name
      fill_in "virtual_gift_card_gift_message", with: new_gift_message
      fill_in "virtual_gift_card_send_email_at", with: Date.tomorrow

      click_button "Update"
      expect(page).to have_content("Gift card updated!")
      expect(gift_card.reload.recipient_name).to eq(new_recipient_name)
      expect(gift_card.recipient_email).to eq(new_recipient_email)
      expect(gift_card.purchaser_name).to eq(new_purchaser_name)
      expect(gift_card.gift_message).to eq(new_gift_message)
    end
  end

  describe "lookup a gift card" do
    let(:gift_card) {
      create(:redeemable_virtual_gift_card,
             recipient_name: "Daeva",
             recipient_email: "dog@example.com")
    }
    let(:other_gift_card) { create(:redeemable_virtual_gift_card) }
    let(:order) { gift_card.line_item.order }

    it "can lookup gift card by recipient email" do
      visit spree.admin_gift_cards_path

      fill_in "q[recipient_email_cont]", with: gift_card.recipient_email
      click_button "Lookup Gift Card"

      expect(page).to have_content(gift_card.purchaser.email)
      expect(page).not_to have_content(other_gift_card.purchaser.email)
    end

    it "can lookup gift card by order number" do
      visit spree.admin_gift_cards_path

      fill_in "q[order_number_cont]", with: order.number
      click_button "Lookup Gift Card"

      expect(page).to have_content(gift_card.purchaser.email)
      expect(page).not_to have_content(other_gift_card.purchaser.email)
    end
  end
end
