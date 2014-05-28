require 'spec_helper'

describe "StoreCredit" do

  let(:currency) { "TEST" }
  let(:store_credit) { create(:store_credit) }

  describe "validations" do
    describe "used amount should not be greater than the credited amount" do
      context "the used amount is defined" do
        let(:invalid_store_credit) { build(:store_credit, amount: 100, amount_used: 150) }

        it "should not be valid" do
          invalid_store_credit.should_not be_valid
        end

        it "should set the correct error message" do
          invalid_store_credit.valid?
          attribute_name = I18n.t('activerecord.attributes.spree/store_credit.amount_used')
          validation_message = Spree.t('admin.store_credits.errors.amount_used_cannot_be_greater')
          expected_error_message = "#{attribute_name} #{validation_message}"
          invalid_store_credit.errors.full_messages.should include(expected_error_message)
        end
      end

      context "the used amount is not defined yet" do
        let(:store_credit) { build(:store_credit, amount: 100) }

        it "should be valid" do
          store_credit.should be_valid
        end

      end
    end
  end

  describe "#display_amount" do
    it "returns a Spree::Money instance" do
      store_credit.display_amount.should be_instance_of(Spree::Money)
    end
  end

  describe "#display_amount_used" do
    it "returns a Spree::Money instance" do
      store_credit.display_amount_used.should be_instance_of(Spree::Money)
    end
  end
end
