require 'spec_helper'

describe Spree::Admin::GiftCardsController do
  stub_authorization!

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
end
