require 'spec_helper'

describe Spree::Admin::GiftCardsController do
  stub_authorization!
  let!(:gc_category) { create(:store_credit_gift_card_category) }
  let!(:credit_type) { create(:secondary_credit_type, name: "Non-expiring") }

  describe 'GET index' do
    subject { spree_get :index }

    it "returns a 200 status code" do
      subject
      expect(response.code).to eq "200"
    end
  end

  describe 'GET lookup' do
    let(:user) { create :user }
    subject { spree_get :lookup, user_id: user.id }

    it "returns a 200 status code" do
      subject
      expect(response.code).to eq "200"
    end
  end

  describe 'PUT deactivate' do
    let(:user) { create :user }
    let!(:gift_card) { create(:redeemable_virtual_gift_card, line_item: order.line_items.first) }
    let(:order) { create(:shipped_order, line_items_count: 1) }
    let!(:default_refund_reason) { Spree::RefundReason.find_or_create_by!(name: Spree::RefundReason::RETURN_PROCESSING_REASON, mutable: false) }

    subject { spree_put :deactivate, id: gift_card.id, order_id: order.number  }

    context "when successful" do
      it "redirects to the admin order edit page" do
        expect(subject).to redirect_to spree.edit_admin_order_path(order)
      end

      it "deactivates the gift card" do
        subject
        expect(gift_card.reload.deactivated_at).to be_present
      end
    end

    context "when deactivating fails without raising an exception" do
      before { expect_any_instance_of(Spree::VirtualGiftCard).to receive(:deactivate).and_return(false) }

      it "does not deactivate the gift card" do
        subject
        expect(gift_card.reload.deactivated_at).to be_nil
      end

      it "redirects to gift card edit page" do
        expect(subject).to redirect_to spree.edit_admin_order_gift_card_path(order, gift_card)
      end

      it "sets the flash message" do
        subject
        expect(flash[:error]).to eq Spree.t('admin.gift_cards.errors.unable_to_reimburse_gift_card')
      end
    end

    context "when deactivating fails from reimbursement" do
      before { expect_any_instance_of(Spree::VirtualGiftCard).to receive(:deactivate).and_raise(Spree::Reimbursement::IncompleteReimbursementError) }

      it "does not deactivate the gift card" do
        subject
        expect(gift_card.reload.deactivated_at).to be_nil
      end

      it "redirects to gift card edit page" do
        expect(subject).to redirect_to spree.edit_admin_order_gift_card_path(order, gift_card)
      end

      it "sets the flash message" do
        subject
        expect(flash[:error]).to eq Spree.t('admin.gift_cards.errors.unable_to_reimburse_gift_card')
      end
    end
  end

  describe 'POST redeem' do
    let(:user) { create :user }
    let(:gift_card) { create(:redeemable_virtual_gift_card) }
    let(:redemption_code) { gift_card.redemption_code }

    subject { spree_post :redeem, user_id: user.id, gift_card: { redemption_code: redemption_code } }

    context "with a gift card that has not yet been redeemed" do

      it "redirects to store credit index" do
        expect(subject).to redirect_to spree.admin_user_store_credits_path(user)
      end

      it "redeems the gift card" do
        subject
        expect(gift_card.reload.redeemed?).to eq true
      end

      it "sets the redeemer to the correct user" do
        subject
        expect(gift_card.reload.redeemer).to eq user
      end

      it "creates store credit for the user" do
        subject
        expect(user.reload.store_credits.count).to eq 1
      end

      it "sets the store credit equal to the amount of the gift card" do
        subject
        expect(user.reload.store_credits.first.amount).to eq gift_card.amount
      end
    end

    context "with a gift card that has already been redeemed" do
      before(:each) { gift_card.update_attribute(:redeemed_at, Date.yesterday) }

      it "renders the lookup page" do
        subject
        expect(response).to render_template(:lookup)
      end
    end

    context "with a gift card code that does not exist" do
      let(:redemption_code) { "INVALID-REDEMPTION-CODE" }

      it "renders the lookup page" do
        subject
        expect(response).to render_template(:lookup)
      end
    end
  end
end
