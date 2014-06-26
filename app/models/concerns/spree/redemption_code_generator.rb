module Spree::RedemptionCodeGenerator
  def self.generate_redemption_code
    rand(36**16).to_s(36).upcase
  end

  def self.format_redemption_code_for_lookup(redemption_code)
    redemption_code.delete('-')
  end
end
