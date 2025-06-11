# frozen_string_literal: true

require_relative "packages"
require_relative "programs"
require_relative "dotfiles"

module Rbdots
  module DSL
    # Main configuration class that provides the DSL interface
    class Configuration
      attr_reader :packages, :programs, :dotfiles, :user_config

      def initialize
        @packages = {}
        @programs = {}
        @dotfiles = nil
        @user_config = {}
      end

      # Configure user information
      #
      # @yield [user] User configuration block
      def user(&block)
        @user_config_obj = UserConfiguration.new
        block.call(@user_config_obj) if block_given?
        @user_config = @user_config_obj.to_hash
      end

      # Configure packages for various package managers
      #
      # @return [Rbdots::DSL::Packages] The packages configuration object
      def packages
        @packages_dsl ||= Packages.new(@packages)
      end

      # Configure programs
      #
      # @return [Rbdots::DSL::Programs] The programs configuration object
      def programs
        @programs_dsl ||= Programs.new(@programs)
      end

      # Configure dotfiles linking
      #
      # @yield [dotfiles] Dotfiles configuration block
      def dotfiles(&block)
        @dotfiles = Dotfiles.new
        block.call(@dotfiles) if block_given?
        @dotfiles
      end

      # Validate the entire configuration
      #
      # @return [Boolean] True if valid
      # @raise [ValidationError] If configuration is invalid
      def validate!
        validate_packages!
        validate_programs!
        validate_dotfiles!
        true
      end

      private

      # Validate package configurations
      def validate_packages!
        @packages.each do |adapter_name, package_config|
          raise ValidationError, "Unknown package manager: #{adapter_name}" unless Rbdots.adapters.key?(adapter_name)

          package_config.validate!
        end
      end

      # Validate program configurations
      def validate_programs!
        @programs.each do |program_name, program_config|
          raise ValidationError, "Unknown program handler: #{program_name}" unless Rbdots.handlers.key?(program_name)

          program_config.validate!
        end
      end

      # Validate dotfiles configuration
      def validate_dotfiles!
        @dotfiles&.validate!
      end
    end

    # User configuration helper class
    class UserConfiguration
      def initialize
        @config = {}
      end

      # Set user name
      #
      # @param name [String] The user's name
      def name(name)
        @config[:name] = name
      end

      # Set user email
      #
      # @param email [String] The user's email
      def email(email)
        @config[:email] = email
      end

      # Set home directory
      #
      # @param directory [String] The home directory path
      def home_directory(directory)
        @config[:home_directory] = File.expand_path(directory)
      end

      # Convert to hash
      #
      # @return [Hash] The configuration as a hash
      def to_hash
        @config
      end
    end
  end
end
