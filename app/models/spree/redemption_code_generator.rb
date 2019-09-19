module Spree::RedemptionCodeGenerator
  def self.generate_redemption_code
    chars = [('A'..'Z'), ('0'..'9')].map(&:to_a).flatten
    16.times.map { chars[rand(chars.count)] }.join
  end

  def self.format_redemption_code_for_lookup(redemption_code)
    redemption_code.delete('-').upcase
  end
end
