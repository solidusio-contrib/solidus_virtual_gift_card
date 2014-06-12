require 'spec_helper'

describe Spree::Api::UsersController do
  render_views

  stub_api_controller_authentication!

  describe "GET store_credit_history" do

    subject { spree_get :store_credit_history, { id: user_id, format: :json } }

    context "the user is not found" do
      let(:user_id) { nil }

      before { subject }

      it "should set the events variable to nil" do
        assigns(:store_credit_events).should be_nil
      end

      it "returns a 404" do
        subject.status.should eq 404
      end
    end

    context "the user exists but has no store credit" do
      let(:user_id) { api_user.id }

      before { subject }

      it "should set the events variable to empty list" do
        assigns(:store_credit_events).should eq []
      end

      it "returns a 200" do
        subject.status.should eq 200
      end
    end

    context "the user has store credit" do
      let(:user_id)       { api_user.id }
      let!(:store_credit) { create(:store_credit, user: api_user) }

      before { subject }

      it "should contain one store credit event" do
        assigns(:store_credit_events).size.should eq 1
      end

      it "should contain the store credit allocation event" do
        assigns(:store_credit_events).should eq store_credit.store_credit_events
      end

      it "returns a 200" do
        subject.status.should eq 200
      end
    end

  end
end
