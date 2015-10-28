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

    it "can edit recipient information and send email date" do
      visit spree.cart_admin_order_path(order)

      within ".line-item-name" do
        click_link("Edit Details")
      end

      fill_in "virtual_gift_card_recipient_name", with: "Heidi"
      fill_in "virtual_gift_card_recipient_email", with:"heidi@gmail.com"
      fill_in "virtual_gift_card_purchaser_name", with: "Neerali"
      fill_in "virtual_gift_card_gift_message", with: "Sweaters!"
      fill_in "virtual_gift_card_send_email_at", with: Date.tomorrow

      # Just so the datepicker gets out of poltergeists way.
      page.execute_script("$('#virtual_gift_card_send_email_at').datepicker('widget').hide();")

      click_on 'Update'
      expect(page).to have_content("Gift card updated!")
    end
  end
end
