# frozen_string_literal: true

require 'spec_helper'

describe Spree::Payment, type: :model do
  let(:store) { create :store }
  let(:order) { Spree::Order.create(store:) }

  let(:gateway) do
    gateway = Spree::PaymentMethod::BogusCreditCard.create!(active: true, name: 'Bogus gateway')
    allow(gateway).to receive_messages(source_required?: true)
    gateway
  end

  let(:card) { create :credit_card }

  let(:payment) do
    described_class.create! do |payment|
      payment.source = card
      payment.order = order
      payment.payment_method = gateway
      payment.amount = 5
    end
  end

  describe '#invalidate_old_payments' do
    it 'does not invalidate other payments if not valid' do
      payment.save
      invalid_payment = described_class.new(amount: 100, order:, state: 'invalid', payment_method: gateway)
      invalid_payment.save
      expect(payment.reload.state).to eq('checkout')
    end

    context 'with order having other payments' do
      let(:payment_method) { create(:payment_method) }
      let(:payment_source) { create(:credit_card) }
      let(:payment) do
        build(:payment,
          payment_method:,
          source: payment_source,
          order:,
          amount: 5)
      end

      before do
        create(:payment,
          payment_method: existing_payment_method,
          source: existing_payment_source,
          order:,
          amount: 5)
      end

      context 'with store credit payments' do
        let(:existing_payment_method) { create(:store_credit_payment_method) }
        let(:existing_payment_source) { create(:store_credit) }

        it 'does not invalidate existing payments' do
          expect { payment.save! }.not_to(change { order.payments.with_state(:invalid).count })
        end

        context 'when payment itself is a store credit payment' do
          let(:payment_method) { existing_payment_method }
          let(:payment_source) { existing_payment_source }

          it 'does not invalidate existing payments' do
            expect { payment.save! }.not_to(change { order.payments.with_state(:invalid).count })
          end
        end
      end

      context 'with gift card payments' do
        let(:existing_payment_method) { create(:gift_card_payment_method) }
        let(:existing_payment_source) { create(:virtual_gift_card) }

        it 'does not invalidate existing payments' do
          expect { payment.save! }.not_to(change { order.payments.with_state(:invalid).count })
        end

        context 'when payment itself is a store credit payment' do
          let(:payment_method) { existing_payment_method }
          let(:payment_source) { existing_payment_source }

          it 'does not invalidate existing payments' do
            expect { payment.save! }.not_to(change { order.payments.with_state(:invalid).count })
          end
        end
      end

      context 'without store credit payments' do
        let(:existing_payment_method) { create(:payment_method) }
        let(:existing_payment_source) { create(:credit_card) }

        it 'invalidates existing payments' do
          expect { payment.save! }.to(change { order.payments.with_state(:invalid).count })
        end
      end
    end

    describe "invalidating payments updates in memory objects" do
      let(:payment_method) { create(:check_payment_method) }

      before do
        Spree::PaymentCreate.new(order, { amount: 1, payment_method_id: payment_method.id }).build.save!
      end

      it 'does not have stale payments' do
        expect(order.payments.map(&:state)).to contain_exactly('checkout')
        Spree::PaymentCreate.new(order, { amount: 2, payment_method_id: payment_method.id }).build.save!

        expect(order.payments.map(&:state)).to contain_exactly(
          'invalid',
          'checkout'
        )
      end
    end
  end
end
