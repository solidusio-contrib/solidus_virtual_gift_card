require 'spec_helper'

module Spree
  describe ReimbursementType::StoreCredit do
    let(:reimbursement)           { create(:reimbursement, return_items_count: 1) }
    let(:return_item)             { reimbursement.return_items.first }
    let(:payment)                 { reimbursement.order.payments.first }
    let(:simulate)                { false }
    let!(:default_refund_reason)  { Spree::RefundReason.find_or_create_by!(name: Spree::RefundReason::RETURN_PROCESSING_REASON, mutable: false) }

    subject { Spree::ReimbursementType::StoreCredit.reimburse(reimbursement, [return_item], simulate)}

    before do
      reimbursement.update!(total: reimbursement.calculated_total)
    end

    describe '.reimburse' do
      context 'simulate is true' do
        let(:simulate) { true }

        context 'for store credits that the customer used' do
          before do
            Spree::ReimbursementType::StoreCredit.should_receive(:store_credit_payments).and_return([payment])
          end

          it 'creates readonly refunds for all store credit payments' do
            expect(subject.map(&:class)).to eq [Spree::Refund]
            expect(subject.map(&:readonly?)).to eq [true]
          end

          it 'does not save to the database' do
            expect { subject }.to_not change { payment.refunds.count }
          end
        end

        context 'for return items that were not paid for with store credit' do
          before do
            Spree::ReimbursementType::StoreCredit.should_receive(:store_credit_payments).and_return([])
          end

          it 'creates one readonly lump credit for all outstanding balance payable to the customer' do
            expect(subject.map(&:class)).to eq [Spree::Reimbursement::Credit]
            expect(subject.map(&:readonly?)).to eq [true]
            expect(subject.sum(&:amount)).to eq reimbursement.return_items.to_a.sum(&:total)
          end

          it 'does not save to the database' do
            expect { subject }.to_not change { Spree::Reimbursement::Credit.count }
          end
        end
      end

      context 'simulate is false' do
        let(:simulate) { false }

        context 'for store credits that the customer used' do
          before do
            Spree::ReimbursementType::StoreCredit.should_receive(:store_credit_payments).and_return([payment])
          end

          it 'performs refunds for all store credit payments' do
            expect { subject }.to change { payment.refunds.count }.by(1)
            expect(payment.refunds.sum(:amount)).to eq reimbursement.return_items.to_a.sum(&:total)
          end
        end

        context 'for return items that were not paid for with store credit' do
          before do
            Spree::ReimbursementType::StoreCredit.should_receive(:store_credit_payments).and_return([])
          end

          it 'creates one lump credit for all outstanding balance payable to the customer' do
            expect { subject }.to change { Spree::Reimbursement::Credit.count }.by(1)
            expect(subject.sum(&:amount)).to eq reimbursement.return_items.to_a.sum(&:total)
          end
        end
      end
    end
  end
end
