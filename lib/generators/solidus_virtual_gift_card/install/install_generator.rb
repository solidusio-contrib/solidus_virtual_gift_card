module SolidusVirtualGiftCard
  module Generators
    class InstallGenerator < Rails::Generators::Base

      class_option :auto_run_migrations, type: :boolean, default: false

      def add_javascripts
        append_file 'vendor/assets/javascripts/spree/backend/all.js', "//= require spree/backend/solidus_virtual_gift_card\n"
      end

      def include_seed_data
        append_file "db/seeds.rb", <<-SEEDS
\n
SpreeVirtualGiftCard::Engine.load_seed if defined?(SpreeVirtualGiftCard::Engine)
        SEEDS
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=solidus_virtual_gift_card'
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask 'Would you like to run the migrations now? [Y/n]')
        if run_migrations
          run 'bundle exec rake db:migrate'
        else
          puts 'Skipping rake db:migrate, don\'t forget to run it!'
        end
      end
    end
  end
end
