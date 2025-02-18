# frozen_string_literal: true

module SolidusVirtualGiftCard
  module Generators
    class InstallGenerator < Rails::Generators::Base
      class_option :auto_run_migrations, type: :boolean, default: false
      source_root File.expand_path('templates', __dir__)

      def self.exit_on_failure?
        true
      end

      def copy_initializer
        template 'initializer.rb', 'config/initializers/solidus_virtual_gift_card.rb'
        empty_directory 'app/assets/javascripts'
      end

      def copy_gift_card_views
        template 'app/views/checkout/payment/_gift_card.html.erb', 'views/checkout/payment/_gift_card.html.erb'
      end

      def add_javascripts
        file_path = 'vendor/assets/javascripts/spree/frontend/all.js'
        append_file file_path, "\n//= require spree/frontend/solidus_virtual_gift_card\n" if File.exist?(file_path)

        file_path = 'vendor/assets/javascripts/spree/backend/all.js'
        append_file file_path, "\n//= require spree/backend/solidus_virtual_gift_card\n" if File.exist?(file_path)
      end

      def add_stylesheets
        file_path = 'vendor/assets/stylesheets/spree/frontend/all.css'
        inject_into_file file_path, " *= require spree/frontend/solidus_virtual_gift_card\n", before: %r{\*/}, verbose: true if File.exist?(file_path)

        file_path = 'vendor/assets/stylesheets/spree/backend/all.css'
        inject_into_file file_path, " *= require spree/backend/solidus_virtual_gift_card\n", before: %r{\*/}, verbose: true if File.exist?(file_path)
      end

      def add_migrations
        run 'bin/rails railties:install:migrations FROM=solidus_virtual_gift_card'
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask('Would you like to run the migrations now? [Y/n]'))
        if run_migrations
          run 'bin/rails db:migrate'
        else
          puts 'Skipping bin/rails db:migrate, don\'t forget to run it!'
        end
      end
    end
  end
end
