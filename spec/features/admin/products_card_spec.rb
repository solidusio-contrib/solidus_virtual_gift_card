require 'spec_helper'

describe 'Gift Cards', :type => :feature, :js => true do
  stub_authorization!

  let(:admin_user) { create(:admin_user) }

  before do
    allow_any_instance_of(Spree::Admin::BaseController).to receive(:spree_current_user).and_return(admin_user)
  end

  describe "edit product" do
    let(:product) { create(:product, available_on: 1.year.from_now) }

    it "can mark a product as a gift card" do
      visit spree.admin_product_path(product)

      find('#product_gift_card').click

      click_on 'Update'

      expect(page).to have_content("successfully updated!")
      expect(page).to have_field('product_gift_card', checked: true)
    end
  end
end
