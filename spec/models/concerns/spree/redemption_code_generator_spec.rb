# frozen_string_literal: true

require 'spec_helper'

describe Spree::RedemptionCodeGenerator do
  describe '#generate_redemption_code' do
    subject { described_class.generate_redemption_code }

    it 'generates a 16 character alpha-numeric code' do
      code = subject
      expect(code.match('^[a-zA-Z0-9]{16}')[0]).to eq code
    end
  end

  describe '#format_redemption_code_for_lookup' do
    subject { described_class.format_redemption_code_for_lookup(redemption_code) }

    context 'redemption code has no dashes' do
      let(:redemption_code) { '1234ABCD1234ABCD' }

      it 'does nothing to the code' do
        expect(subject).to eq redemption_code
      end
    end

    context 'redemption code 4 groups of 4 characters, separated by dashes' do
      let(:redemption_code) { '1234-ABCD-1234-ABCD' }
      let(:formatted_redemption_code) { '1234ABCD1234ABCD' }

      it 'strips the dashes' do
        expect(subject).to eq formatted_redemption_code
      end
    end

    context 'redemption code is mixed-case' do
      let(:redemption_code) { '1234-aBCd-1234-AbcD' }
      let(:formatted_redemption_code) { '1234ABCD1234ABCD' }

      it 'makes it all upcase' do
        expect(subject).to eq formatted_redemption_code
      end
    end
  end
end
