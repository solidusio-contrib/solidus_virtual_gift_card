require 'spec_helper'

describe 'Gift Cards', :type => :feature, :js => true do
  stub_authorization!

  let(:admin_user) { create(:admin_user) }

  before do
    allow_any_instance_of(Spree::Admin::BaseController).to receive(:spree_current_user).and_return(admin_user)
  end

  describe "edit gift card" do
    let(:gift_card) { create(:redeemable_virtual_gift_card) }
    let(:order) { gift_card.line_item.order }
    let(:new_recipient_name) { "Heidi" }
    let(:new_recipient_email) { "heidi@gmail.com" }
    let(:new_purchaser_name) { "Neerali" }
    let(:new_gift_message) { "Sweaters!" }

    it "can edit recipient information and send email date" do
      visit spree.cart_admin_order_path(order)

      within ".line-item-name" do
        click_link("Edit Details")
      end

      fill_in "virtual_gift_card_recipient_name", with: new_recipient_name
      fill_in "virtual_gift_card_recipient_email", with: new_recipient_email
      fill_in "virtual_gift_card_purchaser_name", with: new_purchaser_name
      fill_in "virtual_gift_card_gift_message", with: new_gift_message
      fill_in "virtual_gift_card_send_email_at", with: Date.tomorrow

      # Just so the datepicker gets out of poltergeists way.
      page.execute_script("$('#virtual_gift_card_send_email_at').datepicker('widget').hide();")

      click_on 'Update'
      expect(page).to have_content("Gift card updated!")
      expect(gift_card.reload.recipient_name).to eq(new_recipient_name)
      expect(gift_card.recipient_email).to eq(new_recipient_email)
      expect(gift_card.purchaser_name).to eq(new_purchaser_name)
      expect(gift_card.gift_message).to eq(new_gift_message)
    end
  end
end
