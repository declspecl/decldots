# frozen_string_literal: true

module Rbdots
  module Handlers
    # Base class for all program configuration handlers
    class Base
      # Configure the program with the given options
      #
      # @param options [Hash] Configuration options specific to the program
      # @raise [NotImplementedError] Must be implemented by subclasses
      def configure(options)
        raise NotImplementedError, "#{self.class} must implement #configure"
      end

      # Validate configuration options
      #
      # @param options [Hash] Configuration options to validate
      # @return [Boolean] True if valid
      # @raise [ValidationError] If options are invalid
      def validate_options(options)
        # Default implementation - can be overridden by subclasses
        true
      end

      # Show what changes would be made without applying them
      #
      # @param options [Hash] Configuration options
      # @return [Hash] Hash describing the changes that would be made
      def diff_configuration(options)
        # Default implementation - should be overridden by subclasses
        { action: :configure, details: "Would configure #{self.class.name.split("::").last.downcase}" }
      end

      protected

      # Get the user's home directory
      #
      # @return [String] Path to the user's home directory
      def home_directory
        File.expand_path("~")
      end

      # Write content to a file, creating directories as needed
      #
      # @param file_path [String] Path to the file to write
      # @param content [String] Content to write to the file
      # @param backup [Boolean] Whether to backup existing file
      def write_file(file_path, content, backup: true)
        original_path = File.expand_path(file_path)

        # Transform path for dry run mode
        actual_path = Rbdots.dry_run_path(original_path)

        # Create directory if it doesn't exist
        FileUtils.mkdir_p(File.dirname(actual_path))

        # Backup existing file if requested and not in dry run mode
        backup_file(actual_path) if backup && !Rbdots.dry_run? && File.exist?(actual_path)

        File.write(actual_path, content)

        if Rbdots.dry_run?
          puts "Would create configuration file: #{original_path} (dry run: #{actual_path})"
        else
          puts "Created configuration file: #{original_path}"
        end
      end

      # Create a backup of an existing file
      #
      # @param file_path [String] Path to the file to backup
      def backup_file(file_path)
        timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
        backup_path = "#{file_path}.backup_#{timestamp}"
        FileUtils.cp(file_path, backup_path)
        puts "Backed up existing file to: #{backup_path}"
      end

      # Read a template file and substitute variables
      #
      # @param template_path [String] Path to the template file
      # @param variables [Hash] Variables to substitute in the template
      # @return [String] The processed template content
      def process_template(template_path, variables = {})
        raise ConfigurationError, "Template file not found: #{template_path}" unless File.exist?(template_path)

        template_content = File.read(template_path)

        variables.each do |key, value|
          template_content.gsub!("{{#{key}}}", value.to_s)
        end

        template_content
      end

      # Check if a file exists and has the expected content
      #
      # @param file_path [String] Path to the file to check
      # @param expected_content [String] Expected file content
      # @return [Boolean] True if file exists and has expected content
      def file_matches_content?(file_path, expected_content)
        actual_path = Rbdots.dry_run_path(File.expand_path(file_path))
        return false unless File.exist?(actual_path)

        File.read(actual_path) == expected_content
      end

      # Get the default configuration directory for the current user
      #
      # @return [String] Path to the user's config directory
      def config_directory
        File.join(home_directory, ".config")
      end

      # Ensure a directory exists, creating it if necessary
      #
      # @param directory_path [String] Path to the directory
      def ensure_directory_exists(directory_path)
        FileUtils.mkdir_p(directory_path) unless Dir.exist?(directory_path)
      end
    end
  end
end
