require 'spec_helper'

describe Spree::PaymentMethod::StoreCredit do
  let(:order)           { create(:order) }
  let(:payment)         { create(:payment, order: order) }
  let(:gateway_options) { payment.gateway_options }

  context "#authorize" do
    it "declines an unknown store credit" do
      resp = subject.authorize(100, nil, gateway_options)
      expect(resp.success?).to be false
      resp.message.should include Spree.t('store_credit_payment_method.unable_to_find')
    end

    it "declines a store credit with insuffient funds" do
      store_credit = create(:store_credit)
      resp = subject.authorize((store_credit.amount_remaining * 100) + 1, store_credit, gateway_options)
      expect(resp.success?).to be false
      resp.message.should include Spree.t('store_credit_payment_method.insufficient_funds')
    end

    it "declines a store credit not matching the order currency" do
      store_credit = create(:store_credit, currency: 'AUD')
      resp = subject.authorize((store_credit.amount_remaining * 100) - 1, store_credit, gateway_options)
      expect(resp.success?).to be false
      resp.message.should include Spree.t('store_credit_payment_method.currency_mismatch')
    end

    it "authorizes a valid store credit" do
      store_credit = create(:store_credit)
      resp = subject.authorize((store_credit.amount_remaining * 100) - 1, store_credit, gateway_options)

      expect(resp.success?).to be true
      resp.authorization.should_not be_nil
    end
  end

  context "#capture" do
    let(:authorized_amount) { 10.00 }

    it "declines an unknown store credit" do
      resp = subject.capture(100, -1, gateway_options)
      expect(resp.success?).to be false
      resp.message.should include Spree.t('store_credit_payment_method.unable_to_find')
    end

    it "declines a store credit when unable to authorize the amount" do
      store_credit = create(:store_credit, amount_authorized: authorized_amount - 1)
      auth_event = create(:store_credit_auth_event, store_credit: store_credit, amount: authorized_amount - 1)
      Spree::StoreCredit.any_instance.stub(authorize: true)

      resp = subject.capture(authorized_amount * 100, auth_event.authorization_code, gateway_options)
      expect(resp.success?).to be false
      resp.message.should include Spree.t('store_credit_payment_method.insufficient_authorized_amount')
    end

    it "declines a store credit not matching the order currency" do
      store_credit = create(:store_credit, currency: 'AUD', amount_authorized: authorized_amount)
      auth_event = create(:store_credit_auth_event, store_credit: store_credit, amount: authorized_amount)

      resp = subject.capture(authorized_amount * 100, auth_event.authorization_code, gateway_options)
      expect(resp.success?).to be false
      resp.message.should include Spree.t('store_credit_payment_method.currency_mismatch')
    end

    it "captures a valid store credit" do
      store_credit = create(:store_credit, amount_authorized: authorized_amount)
      auth_event = create(:store_credit_auth_event, store_credit: store_credit, amount: authorized_amount)

      resp = subject.capture(authorized_amount * 100, auth_event.authorization_code, gateway_options)
      expect(resp.success?).to be true
      resp.message.should include Spree.t('store_credit_payment_method.successful_action', action: Spree::StoreCredit::CAPTURE_ACTION)
    end
  end

  context "#void" do
    it "declines an unknown store credit" do
      resp = subject.void(1)
      expect(resp.success?).to be false
      resp.message.should include Spree.t('store_credit_payment_method.unable_to_find')
    end

    it "returns an error response when the store credit isn't voided successfully" do
      auth_event = create(:store_credit_auth_event)
      Spree::StoreCredit.any_instance.stub(void: false)

      resp = subject.void(auth_event.authorization_code, gateway_options)
      expect(resp.success?).to be false
    end

    it "voids a valid store credit void request" do
      auth_event = create(:store_credit_auth_event)

      resp = subject.void(auth_event.authorization_code)
      expect(resp.success?).to be true
      resp.message.should include Spree.t('store_credit_payment_method.successful_action', action: Spree::StoreCredit::VOID_ACTION)
    end
  end

  context "#purchase" do
    it "declines a purchase if it can't find a pending credit for the correct amount" do
      amount = 100.0
      store_credit = create(:store_credit)
      auth_code = store_credit.generate_authorization_code
      store_credit.store_credit_events.create!(action: Spree::StoreCredit::ELIGIBLE_ACTION,
                                               amount: amount,
                                               authorization_code: auth_code)
      store_credit.store_credit_events.create!(action: Spree::StoreCredit::CAPTURE_ACTION,
                                               amount: amount,
                                               authorization_code: auth_code)

      resp = subject.purchase(amount * 100.0, store_credit, gateway_options)
      expect(resp.success?).to be false
      resp.message.should include Spree.t('store_credit_payment_method.unable_to_find')
    end

    it "captures a purchase if it can find a pending credit for the correct amount" do
      amount = 100.0
      store_credit = create(:store_credit)
      auth_code = store_credit.generate_authorization_code
      store_credit.store_credit_events.create!(action: Spree::StoreCredit::ELIGIBLE_ACTION,
                                               amount: amount,
                                               authorization_code: auth_code)

      resp = subject.purchase(amount * 100.0, store_credit, gateway_options)
      expect(resp.success?).to be true
      resp.message.should include Spree.t('store_credit_payment_method.successful_action', action: Spree::StoreCredit::CAPTURE_ACTION)
    end
  end

  context "#credit" do
    it "declines an unknown store credit" do
      resp = subject.credit(100.0, 1, gateway_options)
      expect(resp.success?).to be false
      resp.message.should include Spree.t('store_credit_payment_method.unable_to_find')
    end

    it "returns an error response when the store credit isn't credited successfully" do
      auth_event = create(:store_credit_auth_event)
      Spree::StoreCredit.any_instance.stub(credit: false)

      resp = subject.credit(100.0, auth_event.authorization_code, gateway_options)
      expect(resp.success?).to be false
    end

    it "credits a valid store credit credit request" do
      auth_event = create(:store_credit_auth_event)
      Spree::StoreCredit.any_instance.stub(credit: true)

      resp = subject.credit(100.0, auth_event.authorization_code, gateway_options)
      expect(resp.success?).to be true
      resp.message.should include Spree.t('store_credit_payment_method.successful_action', action: Spree::StoreCredit::CREDIT_ACTION)
    end
  end
end
