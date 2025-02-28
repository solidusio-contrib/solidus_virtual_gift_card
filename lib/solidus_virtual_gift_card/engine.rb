# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

module SolidusVirtualGiftCard
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace ::Spree

    engine_name 'solidus_virtual_gift_card'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    if SolidusSupport.backend_available?
      paths["app/controllers"] << "lib/solidus_virtual_gift_card/controllers/backend"
    end

    initializer 'solidus_virtual_gift_card.environment', before: :load_config_initializers do
      SolidusVirtualGiftCard::Config = SolidusVirtualGiftCard::Configuration.new
    end

    initializer "virtual_gift_card.add_static_preference", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << 'Spree::PaymentMethod::GiftCard'
      app.config.to_prepare do
        ::Spree::Config.static_model_preferences.add(
          ::Spree::PaymentMethod::GiftCard,
          'gift_card_payment_method',
          {}
        )
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
