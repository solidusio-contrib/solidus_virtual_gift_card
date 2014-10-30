require 'spec_helper'

describe Spree::Admin::GiftCardsController do
  stub_authorization!
  let!(:gc_category) { create(:store_credit_gift_card_category) }
  let!(:secondary_credit_type) { create(:secondary_credit_type) }

  describe 'GET index' do
    subject { spree_get :index }

    it "returns a 200 status code" do
      subject
      response.code.should eq "200"
    end
  end

  describe 'GET show' do
    let(:gift_card) { create(:virtual_gift_card) }
    let(:redemption_code) { gift_card.redemption_code }

    subject { spree_get :show, id: redemption_code }

    context 'with a valid redemption code' do
      it 'loads the gift cards' do
        subject
        assigns(:gift_cards).should eq [gift_card]
      end

      it 'returns a 200 status code' do
        subject
        response.code.should eq '200'
      end
    end

    context 'with an invalid redemption code' do
      let(:redemption_code) { "DOES-NOT-EXIST" }

      it "redirects to index" do
        subject.should redirect_to spree.admin_gift_cards_path
      end

      it "sets the flash error" do
        subject
        flash[:error].should eq Spree.t('admin.gift_cards.errors.not_found')
      end
    end
  end

  describe 'GET lookup' do
    let(:user) { create :user }
    subject { spree_get :lookup, user_id: user.id }

    it "returns a 200 status code" do
      subject
      response.code.should eq "200"
    end
  end

  describe 'POST redeem' do
    let(:user) { create :user }
    let(:gift_card) { create(:virtual_gift_card) }
    let(:redemption_code) { gift_card.redemption_code }

    subject { spree_post :redeem, user_id: user.id, gift_card: { redemption_code: redemption_code } }

    context "with a gift card that has not yet been redeemed" do

      it "redirects to store credit index" do
        subject.should redirect_to spree.admin_user_store_credits_path(user)
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
        user.reload.store_credits.count.should eq 1
      end

      it "sets the store credit equal to the amount of the gift card" do
        subject
        user.reload.store_credits.first.amount.should eq gift_card.amount
      end
    end

    context "with a gift card that has already been redeemed" do
      before(:each) { gift_card.update_attribute(:redeemed_at, Date.yesterday) }

      it "renders the lookup page" do
        subject
        response.should render_template(:lookup)
      end
    end

    context "with a gift card code that does not exist" do
      let(:redemption_code) { "INVALID-REDEMPTION-CODE" }

      it "renders the lookup page" do
        subject
        response.should render_template(:lookup)
      end
    end
  end
end
