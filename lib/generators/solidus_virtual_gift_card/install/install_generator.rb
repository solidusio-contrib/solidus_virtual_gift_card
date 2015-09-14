module SolidusVirtualGiftCard
  module Generators
    class InstallGenerator < Rails::Generators::Base

      class_option :auto_run_migrations, type: :boolean, default: false
      class_option :migrate, :type => :boolean, :default => true, :banner => 'Run migrations'

      def prepare_options
        @run_migrations = options[:migrate]
      end

      def add_javascripts
        append_file 'vendor/assets/javascripts/spree/backend/all.js', "//= require spree/backend/solidus_virtual_gift_card\n"
      end

      def add_stylesheets
        inject_into_file 'vendor/assets/stylesheets/spree/backend/all.css', " *= require spree/backend/solidus_virtual_gift_card\n", before: /\*\//, verbose: true
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
        if run_migrations= @run_migrations
          run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask 'Would you like to run the migrations now? [Y/n]')
          if run_migrations
            run 'bundle exec rake db:migrate'
          end
        end
        if !run_migrations
          say_status :skipping, "migrations (don't forget to run rake db:migrate)"
        end
      end
    end
  end
end
