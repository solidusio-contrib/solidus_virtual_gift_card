# frozen_string_literal: true

Rails.application.config.to_prepare do
  if defined?(Spree::Backend)
    Spree::Backend::Config.configure do |config|
      config.menu_items = config.menu_items.map do |item|
        if item.label.to_sym == :users
          # The API of the MenuItem class changes in Solidus 4.2.0
          if item.respond_to?(:children)
            unless item.children.any? { |child| child.label == :gift_cards }
              item.children << Spree::BackendConfiguration::MenuItem.new(
                label: :gift_cards,
                condition: -> { can?(:display, Spree::VirtualGiftCard) },
                url: -> { Spree::Core::Engine.routes.url_helpers.admin_gift_cards_path },
                match_path: /gift_cards/
              )
            end
          else
            item.sections << :gift_cards
          end
        end
        item
      end
    end
  end
end
