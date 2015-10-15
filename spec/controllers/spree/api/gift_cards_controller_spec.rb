require 'spec_helper'

describe Spree::Api::GiftCardsController do
  render_views
  let!(:credit_type) { create(:secondary_credit_type, name: "Non-expiring") }
  let!(:gc_category) { create(:store_credit_gift_card_category) }

  describe "POST redeem" do
    let(:gift_card) { create(:redeemable_virtual_gift_card) }

    let(:parameters) do
      {
        redemption_code: gift_card.redemption_code
      }
    end

    subject { spree_post :redeem, parameters, { format: :json } }

    context "the user is not logged in" do

      before { subject }

      it "returns a 401" do
        expect(response.status).to eq 401
      end
    end

    context "the current api user is authenticated" do
      let(:api_user) { create(:user) }

      before do
        allow(controller).to receive(:load_user)
        controller.instance_variable_set(:@current_api_user, api_user)
      end

      let(:parsed_response) { HashWithIndifferentAccess.new(JSON.parse(response.body)) }

      context "given an invalid gift card redemption code" do
        before { subject }

        let(:parameters) do
          {
            redemption_code: 'INVALID_CODE'
          }
        end

        it 'does not find the gift card' do
          expect(assigns(:gift_card)).to eq nil
        end

        it 'contains an error message' do
          expect(parsed_response['error_message']).to be_present
        end

        it "returns a 404" do
          expect(subject.status).to eq 404
        end
      end

      context "there is no redemption code in the request body" do
        let(:parameters) { {} }

        it "returns a 404" do
          expect(subject.status).to eq 404
        end
      end

      context "given a valid gift card redemption code" do

        it 'finds the gift card' do
          subject
          expect(assigns(:gift_card)).to eq gift_card
        end

        it 'redeems the gift card' do
          allow(Spree::VirtualGiftCard).to receive(:active_by_redemption_code).and_return(gift_card)
          expect(gift_card).to receive(:redeem).with(api_user)
          subject
        end

        it "returns a 201" do
          subject
          expect(subject.status).to eq 201
        end
      end
    end
  end
end
