require 'spec_helper'

describe Spree::Api::GiftCardsController do
  render_views

  describe "POST redeem" do
    let(:gift_card) { create(:virtual_gift_card) }

    let(:parameters) do
      {
        redemption_code: gift_card.redemption_code
      }
    end

    subject { spree_post :redeem, parameters, { format: :json } }

    context "the user is not logged in" do

      before { subject }

      it "returns a 401" do
        response.status.should eq 401
      end
    end

    context "the current api user is authenticated" do
      stub_api_controller_authentication!

      let(:parsed_response) { HashWithIndifferentAccess.new(JSON.parse(response.body)) }

      context "given an invalid gift card redemption code" do
        before { subject }

        let(:parameters) do
          {
            redemption_code: 'INVALID_CODE'
          }
        end

        it 'does not find the gift card' do
          assigns(:gift_card).should eq nil
        end

        it 'contains an error message' do
          parsed_response['error_message'].should be_present
        end

        it "returns a 404" do
          subject.status.should eq 404
        end
      end

      context "there is no redemption code in the request body" do
        let(:parameters) { {} }

        it "returns a 422" do
          subject.status.should eq 422
        end
      end

      context "given a valid gift card redemption code" do

        it 'finds the gift card' do
          subject
          assigns(:gift_card).should eq gift_card
        end

        it 'redeems the gift card' do
          Spree::VirtualGiftCard.stub(:active_by_redemption_code).and_return(gift_card)
          gift_card.should_receive(:redeem).with(api_user)
          subject
        end

        it "returns a 201" do
          subject
          subject.status.should eq 201
        end
      end
    end
  end
end
