require 'spec_helper'

describe Spree::Admin::PaymentsController do
  stub_authorization!

  describe "GET new" do

    subject { spree_get :new, order_id: order.to_param }

    context "the order does not have an associated user" do
      let(:order) { create(:store_credits_order_without_user) }

      before { subject }

      it "should set the store credits variable to nil" do
        assigns(:store_credits).should be_nil
      end
    end

    context "the user does not have any store credits" do
      let(:order) { create(:order) }

      before { subject }

      it "should set the store credits variable to an empty list" do
        assigns(:store_credits).should be_empty
      end
    end

    context "the user has store credits" do
      let(:store_credit) { create(:store_credit) }
      let(:order)        { create(:order, user: store_credit.user) }

      before { subject }

      it "should set the store credits variable to contain the user's store credit" do
        assigns(:store_credits).should eq [store_credit]
      end
    end
  end

  describe "POST create" do
    let(:payment_params) do
      {
        amount: 10.0,
        payment_method_id: payment.payment_method_id
      }
    end

    subject { spree_post :create, order_id: order.to_param, payment: payment_params }

    context "the payment method is store credit" do
      let(:order)   { payment.order }
      let(:payment) { create(:store_credit_payment) }

      before do
        payment.source.update_attributes(user_id: order.user.id)
      end

      context "a store credit id is provided" do
        let(:payment_params) do
          {
            amount: 10.0,
            store_credit_id: payment.source.id,
            payment_method_id: payment.payment_method_id
          }
        end

        it "should redirect to the payments page" do
          subject
          response.should redirect_to spree.admin_order_payments_path(order)
        end

        it "creates a store credit payment" do
          expect { subject }.to change { Spree::Payment.where(source_type: "Spree::StoreCredit").count }.by(1)
        end
      end

      context "a store credit id is not provided" do
        it "should redirect to the payments page" do
          subject
          response.should redirect_to spree.admin_order_payments_path(order)
        end

        it "does not create any store credit payment" do
          expect { subject }.to_not change { Spree::Payment.where(source_type: "Spree::StoreCredit").count }
        end
      end
    end

    context "the payment method is not store credit" do
      let(:order)   { payment.order }
      let(:payment) { create(:payment) }

      it "should redirect to the payments page" do
        subject
        response.should redirect_to spree.admin_order_payments_path(order)
      end

      it "does not create any store credit payment" do
        expect { subject }.to_not change { Spree::Payment.where(source_type: "Spree::StoreCredit").count }
      end
    end
  end
end
