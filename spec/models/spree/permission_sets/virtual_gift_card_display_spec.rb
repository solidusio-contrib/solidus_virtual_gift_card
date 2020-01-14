# frozen_string_literal: true

require 'spec_helper'

describe Spree::PermissionSets::VirtualGiftCardDisplay do
  subject { ability }

  let(:ability) { Spree::Ability.new nil }

  context 'when activated' do
    before do
      described_class.new(ability).activate!
    end

    it { is_expected.to be_able_to(:admin, Spree::VirtualGiftCard) }
    it { is_expected.to be_able_to(:display, Spree::VirtualGiftCard) }
  end

  context 'when not activated' do
    it { is_expected.not_to be_able_to(:admin, Spree::VirtualGiftCard) }
    it { is_expected.not_to be_able_to(:display, Spree::VirtualGiftCard) }
  end
end
