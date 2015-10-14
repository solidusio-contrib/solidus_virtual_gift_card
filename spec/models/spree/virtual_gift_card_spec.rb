require 'spec_helper'

describe Spree::VirtualGiftCard do
  let!(:gc_category) { create(:store_credit_gift_card_category) }
  let!(:credit_type) { create(:secondary_credit_type, name: "Non-expiring") }

  context 'validations' do
    let(:invalid_gift_card) { build(:virtual_gift_card, amount: 0) }

    context 'given an amount less than one' do
      it 'is not valid' do
        expect(invalid_gift_card).not_to be_valid
      end

      it 'adds an error to amount' do
        invalid_gift_card.save
        expect(invalid_gift_card.errors.full_messages).to include 'Amount must be greater than 0'
      end
    end
  end

  context 'before create callbacks' do
    let(:gift_card) { build(:virtual_gift_card) }
    subject { gift_card.save }

    context 'a redemption code is set already' do
      before { gift_card.redemption_code = 'foo' }
      it 'keeps that redemption code' do
        subject
        expect(gift_card.redemption_code).to eq 'foo'
      end
    end

    context 'no collision on redemption code' do
      it 'sets an initial redemption code' do
        subject
        expect(gift_card.redemption_code).to be_present
      end
    end


    context 'there is a collision on redemption code' do
      context 'the existing giftcard has not been redeemed yet' do
        let!(:existing_giftcard) { create(:virtual_gift_card) }
        let(:expected_code) { 'EXPECTEDCODE' }
        let(:generator) { Spree::RedemptionCodeGenerator }

        it 'recursively generates redemption codes' do
          expect(generator).to receive(:generate_redemption_code).and_return(existing_giftcard.redemption_code)
          expect(generator).to receive(:generate_redemption_code).and_return(expected_code)

          subject

          expect(gift_card.redemption_code).to eq expected_code
        end
      end

      context 'the existing gift card has been redeemed' do
        let!(:existing_giftcard) { create(:virtual_gift_card, redeemed_at: Time.now) }
        let(:generator) { Spree::RedemptionCodeGenerator }

        it 'recursively generates redemption codes' do
          expect(generator).to receive(:generate_redemption_code).and_return(existing_giftcard.redemption_code)

          subject

          expect(gift_card.redemption_code).to eq existing_giftcard.redemption_code
        end
      end
    end
  end

  describe '#redeemed?' do
    let(:gift_card) { build(:virtual_gift_card) }

    it 'is redeemed if there is a redeemed_at set' do
      gift_card.redeemed_at = Time.now
      expect(gift_card.redeemed?).to be true
    end

    it 'is not redeemed if there is no timestamp for redeemed_at' do
      expect(gift_card.redeemed?).to be false
    end
  end

  describe '#redeem' do
    let(:gift_card) { create(:virtual_gift_card) }
    let(:redeemer) { create(:user) }
    subject { gift_card.redeem(redeemer) }

    context 'it is not redeemable' do
      before { gift_card.redeemable = false }

      it 'should return false' do
        expect(subject).to be false
      end

      context 'does nothing to the gift card' do
        it 'should not create a store credit' do
          expect(gift_card.store_credit).not_to be_present
        end

        it 'should not update the gift card' do
          expect { subject }.to_not change{ gift_card }
        end
      end
    end


    context 'it has already been redeemed' do
      before { gift_card.redeemed_at = Date.yesterday }

      it 'should return false' do
        expect(subject).to be false
      end

      context 'does nothing to the gift card' do
        it 'should not create a store credit' do
          expect(gift_card.store_credit).not_to be_present
        end

        it 'should not update the gift card' do
          expect { subject }.to_not change{ gift_card }
        end
      end
    end

    context 'it has not been redeemed already and is redeemable' do
      context 'generates a store credit' do
        before { subject }
        let(:store_credit) { gift_card.store_credit }

        it 'sets the relationship' do
          expect(store_credit).to be_present
        end

        it 'sets the store credit amount' do
          expect(store_credit.amount).to eq gift_card.amount
        end

        it 'sets the store credit currency' do
          expect(store_credit.currency).to eq gift_card.currency
        end

        it "sets the 'Gift Card' category" do
          expect(store_credit.category).to eq gc_category
        end

        it 'sets the redeeming user on the store credit' do
          expect(store_credit.user).to eq redeemer
        end

        it 'sets the created_by user on the store credit' do
          expect(store_credit.created_by).to eq redeemer
        end

        it 'sets a memo on store credit for admins to reference the redemption code' do
          expect(store_credit.memo).to eq gift_card.memo
        end
      end

      it 'returns true' do
        expect(subject).to be true
      end

      it 'sets redeemed_at' do
        subject
        expect(gift_card.redeemed_at).to be_present
      end

      it 'sets the redeeming user association' do
        subject
        expect(gift_card.redeemer).to be_present
      end

      it 'sets the admin as the store credit event originator' do
        expect { subject }.to change { Spree::StoreCreditEvent.count }.by(1)
        expect(Spree::StoreCreditEvent.last.originator).to eq gift_card
      end
    end
  end

  describe '#formatted_redemption_code' do
    let(:redemption_code) { 'AAAABBBBCCCCDDDD' }
    let(:formatted_redemption_code) { 'AAAA-BBBB-CCCC-DDDD' }
    let(:gift_card) { build(:virtual_gift_card) }

    subject { gift_card.formatted_redemption_code }

    it 'inserts dashes into the code after every 4 characters' do
      expect(gift_card).to receive(:redemption_code).and_return(redemption_code)
      expect(subject).to eq formatted_redemption_code
    end
  end
end
