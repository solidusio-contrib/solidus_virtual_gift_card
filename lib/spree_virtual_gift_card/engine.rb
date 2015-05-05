module SpreeVirtualGiftCard
  class Engine < Rails::Engine
    require 'spree/core'
    require 'spree_store_credits'

    isolate_namespace Spree
    engine_name 'spree_virtual_gift_card'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
