require 'spec_helper'

describe Spree::RedemptionCodeGenerator do
  describe '#generate_redemption_code' do
    subject { Spree::RedemptionCodeGenerator.generate_redemption_code }

    it 'generates a 16 character alpha-numeric code' do
      code = subject
      code.match('^[a-zA-Z0-9]{16}')[0].should eq code
    end
  end

  describe '#format_redemption_code_for_lookup' do
    let(:redemption_code) { "1234ABCD1234ABCD" }
    subject { Spree::RedemptionCodeGenerator.format_redemption_code_for_lookup(redemption_code) }

    context 'redemption code has no dashes' do
      it 'does nothing to the code' do
        subject.should eq redemption_code
      end
    end

    context 'redemption code 4 groups of 4 characters, separated by dashes' do
      let(:redemption_code) { "1234-ABCD-1234-ABCD" }
      let(:formatted_redemption_code) { "1234ABCD1234ABCD" }

      it 'strips the dashes' do
        subject.should eq formatted_redemption_code
      end
    end
  end
end
