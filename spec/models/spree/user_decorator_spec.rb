require 'spec_helper'

describe "User" do

  describe "#total_available_store_credit" do
    context "user does not have any associated store credits" do
      subject { create(:user) }

      it "returns 0" do
        subject.total_available_store_credit.should be_zero
      end
    end

    context "user has several associated store credits" do
      let(:user)                     { create(:user) }
      let(:amount)                   { 120.25 }
      let(:additional_amount)        { 55.75 }
      let(:store_credit)             { create(:store_credit, user: user, amount: amount, amount_used: 0.0) }
      let!(:additional_store_credit) { create(:store_credit, user: user, amount: additional_amount, amount_used: 0.0) }

      subject { store_credit.user}

      context "part of the store credit has been used" do
        let(:amount_used) { 35.00 }

        before { store_credit.update_attributes(amount_used: amount_used) }

        context "part of the store credit has been authorized" do
          let(:authorized_amount) { 10 }

          before { additional_store_credit.update_attributes(amount_authorized: authorized_amount) }

          it "returns sum of amounts minus used amount and authorized amount" do
            subject.total_available_store_credit.to_f.should eq (amount + additional_amount - amount_used - authorized_amount)
          end
        end

        context "there are no authorized amounts on any of the store credits" do
          it "returns sum of amounts minus used amount" do
            subject.total_available_store_credit.to_f.should eq (amount + additional_amount - amount_used)
          end
        end
      end

      context "store credits have never been used" do
        context "part of the store credit has been authorized" do
          let(:authorized_amount) { 10 }

          before { additional_store_credit.update_attributes(amount_authorized: authorized_amount) }

          it "returns sum of amounts minus authorized amount" do
            subject.total_available_store_credit.to_f.should eq (amount + additional_amount - authorized_amount)
          end
        end

        context "there are no authorized amounts on any of the store credits" do
          it "returns sum of amounts" do
            subject.total_available_store_credit.to_f.should eq (amount + additional_amount)
          end
        end
      end

      context "all store credits have never been used or authorized" do
        it "returns sum of amounts" do
          subject.total_available_store_credit.to_f.should eq (amount + additional_amount)
        end
      end

    end
  end

end
