module Spree::RedemptionCodeGenerator
  def self.generate_redemption_code
    rand(36**16).to_s(36).upcase.scan(/.{4}/).join('-')
  end
end
