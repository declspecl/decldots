# frozen_string_literal: true

module Rbdots
  module Adapters
    # Base class for all package manager adapters
    class Base
      # Install packages
      #
      # @param packages [Array<String>] Package names to install
      # @raise [NotImplementedError] Must be implemented by subclasses
      def install(packages)
        raise NotImplementedError, "#{self.class} must implement #install"
      end

      # Uninstall packages
      #
      # @param packages [Array<String>] Package names to uninstall
      # @raise [NotImplementedError] Must be implemented by subclasses
      def uninstall(packages)
        raise NotImplementedError, "#{self.class} must implement #uninstall"
      end

      # Update packages
      #
      # @param packages [Array<String>, nil] Specific packages to update, or nil for all
      # @raise [NotImplementedError] Must be implemented by subclasses
      def update(packages = nil)
        raise NotImplementedError, "#{self.class} must implement #update"
      end

      # Check if a package is installed
      #
      # @param package [String] Package name to check
      # @return [Boolean] True if package is installed
      # @raise [NotImplementedError] Must be implemented by subclasses
      def installed?(package)
        raise NotImplementedError, "#{self.class} must implement #installed?"
      end

      # Get list of installed packages
      #
      # @return [Array<String>] List of installed package names
      # @raise [NotImplementedError] Must be implemented by subclasses
      def list_installed
        raise NotImplementedError, "#{self.class} must implement #list_installed"
      end

      protected

      # Execute a shell command and return the result
      #
      # @param command [String] The command to execute
      # @param capture_output [Boolean] Whether to capture command output
      # @return [String, Boolean] Command output if captured, or true/false for success
      def execute_command(command, capture_output: false)
        if capture_output
          result = `#{command} 2>&1`
          return result if $?.success?

          raise CommandError, "Command failed: #{command}\nOutput: #{result}"
        else
          success = system(command)
          raise CommandError, "Command failed: #{command}" unless success

          success
        end
      end

      # Check if a command exists in the system PATH
      #
      # @param command [String] The command to check
      # @return [Boolean] True if command exists
      def command_exists?(command)
        system("which #{command} > /dev/null 2>&1")
      end

      # Ensure the package manager is available
      #
      # @raise [ConfigurationError] If package manager is not available
      def ensure_package_manager_available!
        manager_command = self.class.name.split("::").last.downcase
        return if command_exists?(manager_command)

        raise ConfigurationError, "#{manager_command} is not installed or not in PATH"
      end
    end

    # Error raised when a command execution fails
    class CommandError < Rbdots::Error; end
  end
end
