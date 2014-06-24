require 'spec_helper'

describe Spree::RedemptionCodeGenerator do
  describe '#generate_redemption_code' do
    subject { Spree::RedemptionCodeGenerator.generate_redemption_code }

    context 'generates a 16 character code with 3 dashes' do
      it 'has 19 characters' do
        subject.length.should eq 19
      end

      it 'has a format of 4 groups of 4 characters, split by dashes' do
        code = subject
        code.match('(\w{4}-?){4}')[0].should eq code
      end
    end
  end
end
