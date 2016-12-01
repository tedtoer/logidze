# frozen_string_literal: true
require "rails/generators"
require "rails/generators/active_record/migration/migration_generator"

module Logidze
  module Generators
    class ModelGenerator < ::ActiveRecord::Generators::Base # :nodoc:
      source_root File.expand_path('../templates', __FILE__)

      class_option :limit, type: :numeric, optional: true, desc: "Specify history size limit"

      class_option :only, type: :string, optional: true,
                   desc: "Specify columns for filtering by whitelist"

      class_option :except, type: :string, optional: true,
                   desc: "Specify columns for filtering by blacklist"

      class_option :backfill, type: :boolean, optional: true,
                              desc: "Add query to backfill existing records history"

      class_option :only_trigger, type: :boolean, optional: true,
                                  desc: "Create trigger-only migration"

      def generate_migration
        migration_template "migration.rb.erb", "db/migrate/#{migration_file_name}"
      end

      def inject_logidze_to_model
        indents = "  " * (class_name.scan("::").count + 1)

        inject_into_class(model_file_path, class_name.demodulize, "#{indents}has_logidze\n")
      end

      no_tasks do
        def migration_name
          "add_logidze_to_#{plural_table_name}"
        end

        def migration_file_name
          "#{migration_name}.rb"
        end

        def args_string
          args_array = []

          args_array.push(options[:limit]) if options[:limit].present?

          if options[:only].present?
            args_array.push('null') if options[:limit].blank?
            args_array.push(columns_to_sql_arg(options[:only]))
            args_array.push('TRUE')
          elsif options[:except].present?
            args_array.push('null') if options[:limit].blank?
            args_array.push(columns_to_sql_arg(options[:except]))
            args_array.push('FALSE')
          end

          args_array.join(', ')
        end

        def backfill?
          options[:backfill]
        end

        def only_trigger?
          options[:only_trigger]
        end
      end

      private

      def model_file_path
        File.join("app", "models", "#{file_path}.rb")
      end

      def columns_to_sql_arg(columns_string)
        "'{#{columns_string}}'".gsub('"', '').gsub(',', ', ')
      end
    end
  end
end
