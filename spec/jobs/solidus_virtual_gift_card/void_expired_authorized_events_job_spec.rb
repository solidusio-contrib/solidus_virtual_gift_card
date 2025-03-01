# frozen_string_literal: true

RSpec.describe SolidusVirtualGiftCard::VoidExpiredAuthorizedEventsJob, type: :job do
  subject(:call_perform_now) { -> { described_class.perform_now }.call }

  let(:order) { instance_double('Spree::Order', last_for_user?: last_for_user) }

  let(:allocated_gift_card) { create(:redeemable_virtual_gift_card) }
  let(:authorized_expired_gift_card) { create(:redeemable_virtual_gift_card) }
  let(:authorized_captured_gift_card) { create(:redeemable_virtual_gift_card) }
  let(:authorized_gift_card) { create(:redeemable_virtual_gift_card) }

  before do
    allocated_gift_card
    allocated_gift_card.events.update_all(created_at: 3.months.ago) # rubocop:disable Rails/SkipsModelValidations

    authorized_expired_gift_card.events.update_all(created_at: 3.months.ago) # rubocop:disable Rails/SkipsModelValidations
    create(:virtual_gift_card_auth_event, virtual_gift_card: authorized_expired_gift_card, created_at: 2.months.ago)

    authorized_captured_gift_card.events.update_all(created_at: 3.months.ago) # rubocop:disable Rails/SkipsModelValidations
    create(:virtual_gift_card_auth_event, virtual_gift_card: authorized_captured_gift_card, created_at: 2.months.ago)
    create(:virtual_gift_card_capture_event, virtual_gift_card: authorized_captured_gift_card, created_at: (2.months - 1.week).ago)

    authorized_gift_card.events.update_all(created_at: 3.months.ago) # rubocop:disable Rails/SkipsModelValidations
    create(:virtual_gift_card_auth_event, virtual_gift_card: authorized_gift_card, created_at: 25.days.ago)
  end

  it 'voids the expired transaction' do
    allow(SolidusVirtualGiftCard::Config).to receive(:authorize_timeout).and_return(1.month)

    expect do
      call_perform_now
    end.to change { Spree::VirtualGiftCardEvent.where(action: Spree::VirtualGiftCard::VOID_ACTION).count }.by(1)
  end

  context 'when the SolidusVirtualGiftCard::Config.authorize_timeout is set to 20 days' do
    it 'voids the expired transactions' do
      allow(SolidusVirtualGiftCard::Config).to receive(:authorize_timeout).and_return(20.days)

      expect do
        call_perform_now
      end.to change { Spree::VirtualGiftCardEvent.where(action: Spree::VirtualGiftCard::VOID_ACTION).count }.by(2)
    end
  end
end
