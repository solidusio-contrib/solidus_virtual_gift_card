require 'spec_helper'

describe "VirtualGiftCard" do
  let!(:gc_category) { create(:store_credit_gift_card_category) }

  context 'validations' do
    let(:invalid_gift_card) { Spree::VirtualGiftCard.new(amount: 0, currency: 'USD') }

    context 'given an amount less than one' do
      it 'is not valid' do
        invalid_gift_card.should_not be_valid
      end

      it 'adds an error to amount' do
        invalid_gift_card.save
        invalid_gift_card.errors.full_messages.should include 'Amount must be greater than 0'
      end
    end
  end

  context 'before create callbacks' do
    let(:gift_card) { Spree::VirtualGiftCard.new(amount: 20, currency: 'USD') }
    subject { gift_card.save }

    context 'no collision on redemption code' do
      it 'sets an initial redemption code' do
        subject
        gift_card.redemption_code.should be_present
      end
    end


    context 'there is a collision on redemption code' do 
      context 'the existing giftcard has not been redeemed yet' do
        let!(:existing_giftcard) { create(:virtual_gift_card) }
        let(:expected_code) { 'EXPECTEDCODE' }
        let(:generator) { Spree::RedemptionCodeGenerator }

        it 'recursively generates redemption codes' do
          generator.should_receive(:generate_redemption_code).and_return(existing_giftcard.redemption_code)
          generator.should_receive(:generate_redemption_code).and_return(expected_code)

          subject

          gift_card.redemption_code.should eq expected_code
        end
      end

      context 'the existing gift card has been redeemed' do
        let!(:existing_giftcard) { create(:virtual_gift_card, redeemed_at: Time.now) }
        let(:generator) { Spree::RedemptionCodeGenerator }

        it 'recursively generates redemption codes' do
          generator.should_receive(:generate_redemption_code).and_return(existing_giftcard.redemption_code)

          subject

          gift_card.redemption_code.should eq existing_giftcard.redemption_code
        end
      end
    end
  end

  describe '#redeemed?' do
    let(:gift_card) { Spree::VirtualGiftCard.new(amount: 20, currency: 'USD') }
    subject { gift_card.save }

    it 'is redeemed if there is a redeemed_at set' do
      gift_card.redeemed_at = Time.now
      subject
      gift_card.redeemed?.should be true
    end

    it 'is not redeemed if there is no timestamp for redeemed_at' do
      subject
      gift_card.redeemed?.should be false
    end
  end

  describe '#redeem' do
    let(:gift_card) { Spree::VirtualGiftCard.create(amount: 20, currency: 'USD') }
    let(:redeemer) { create(:user) }
    subject { gift_card.redeem(redeemer) }

    context 'it has already been redeemed' do
      before { gift_card.redeemed_at = Date.yesterday }

      it 'should return false' do
        subject.should be false
      end

      context 'does nothing to the gift card' do
        it 'should not create a store credit' do
          gift_card.store_credit.should_not be_present
        end

        it 'should not update the gift card' do
          expect { subject }.to_not change{ gift_card }
        end
      end
    end

    context 'it has not been redeemed already' do
      context 'generates a store credit' do
        before { subject }
        let(:store_credit) { gift_card.store_credit }

        it 'sets the relationship' do
          store_credit.should be_present
        end

        it 'sets the store credit amount' do
          store_credit.amount.should eq gift_card.amount
        end

        it 'sets the store credit currency' do
          store_credit.currency.should eq gift_card.currency
        end

        it "sets the 'Gift Card' category" do
          store_credit.category.should eq gc_category
        end

        it 'sets the redeeming user on the store credit' do
          store_credit.user.should eq redeemer
        end

        it 'sets the created_by user on the store credit' do
          store_credit.created_by.should eq redeemer
        end

        it 'sets a memo on store credit for admins to reference the redemption code' do
          store_credit.memo.should eq gift_card.memo
        end
      end

      it 'returns true' do
        subject.should be true
      end

      it 'sets redeemed_at' do
        subject
        gift_card.redeemed_at.should be_present
      end

      it 'sets the redeeming user association' do
        subject
        gift_card.redeemer.should be_present
      end
    end
  end

  describe '#formatted_redemption_code' do
    let(:redemption_code) { 'AAAABBBBCCCCDDDD' }
    let(:formatted_redemption_code) { 'AAAA-BBBB-CCCC-DDDD' }
    let(:gift_card) { Spree::VirtualGiftCard.create(amount: 20, currency: 'USD') }

    subject { gift_card.formatted_redemption_code }

    it 'inserts dashes into the code after every 4 characters' do
      gift_card.should_receive(:redemption_code).and_return(redemption_code)
      subject.should eq formatted_redemption_code
    end
  end
end
