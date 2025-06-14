# frozen_string_literal: true

require "fileutils"
require_relative "rbdots/version"
require_relative "rbdots/engine"
require_relative "rbdots/dsl/configuration"

# Main namespace for the Rbdots declarative dotfile management framework
module Rbdots
    class Error < StandardError; end
    class ConfigurationError < Error; end
    class ValidationError < Error; end

    # Registry for package manager adapters
    @adapters = {}

    # Registry for program configuration handlers
    @handlers = {}

    # Dry run mode configuration
    @dry_run = false
    @dry_run_directory = nil

    class << self
        attr_reader :adapters, :handlers, :dry_run, :dry_run_directory

        # Main DSL entry point for user configurations
        #
        # @yield [config] Configuration block
        # @yieldparam config [Rbdots::DSL::Configuration] The configuration object
        # @return [Rbdots::DSL::Configuration] The configured object
        def configure(&block)
            config = DSL::Configuration.new
            block.call(config) if block_given?
            config
        end

        # Apply a configuration to the system
        #
        # @param config [Rbdots::DSL::Configuration] The configuration to apply
        # @return [Boolean] True if successful
        def apply(config)
            engine = Engine.new
            engine.apply_configuration(config)
        end

        # Show what changes would be applied without actually applying them
        #
        # @param config [Rbdots::DSL::Configuration] The configuration to diff
        # @return [Hash] Hash of changes that would be made
        def diff(config)
            engine = Engine.new
            engine.diff_configuration(config)
        end

        # Register a package manager adapter
        #
        # @param name [Symbol] The name of the adapter
        # @param adapter_class [Class] The adapter class
        def register_adapter(name, adapter_class)
            @adapters[name] = adapter_class
        end

        # Register a program configuration handler
        #
        # @param name [Symbol] The name of the handler
        # @param handler_class [Class] The handler class
        def register_handler(name, handler_class)
            @handlers[name] = handler_class
        end

        # Get an adapter by name
        #
        # @param name [Symbol] The adapter name
        # @return [Class] The adapter class
        # @raise [ConfigurationError] If adapter is not found
        def get_adapter(name)
            @adapters[name] || raise(ConfigurationError, "Unknown adapter: #{name}")
        end

        # Get a handler by name
        #
        # @param name [Symbol] The handler name
        # @return [Class] The handler class
        # @raise [ConfigurationError] If handler is not found
        def get_handler(name)
            @handlers[name] || raise(ConfigurationError, "Unknown handler: #{name}")
        end

        # Enable dry run mode
        #
        # @param enabled [Boolean] Whether to enable dry run mode
        # @param temp_dir [String, nil] Custom temporary directory (optional)
        def enable_dry_run(enabled = true, temp_dir: nil)
            @dry_run = enabled

            if enabled
                require "tmpdir"
                @dry_run_directory = temp_dir || Dir.mktmpdir("rbdots_dry_run_")
                puts "Dry run mode enabled. Files will be created in: #{@dry_run_directory}"

                # Create a basic directory structure
                FileUtils.mkdir_p(File.join(@dry_run_directory, "home"))
                FileUtils.mkdir_p(File.join(@dry_run_directory, "config"))
            else
                @dry_run_directory = nil
                puts "Dry run mode disabled."
            end
        end

        # Disable dry run mode
        def disable_dry_run
            enable_dry_run(false)
        end

        # Transform a real path to a dry run path
        #
        # @param real_path [String] The real file system path
        # @return [String] The dry run equivalent path
        def dry_run_path(real_path)
            return real_path unless @dry_run

            expanded_path = File.expand_path(real_path)
            home_dir = File.expand_path("~")

            if expanded_path.start_with?(home_dir)
                # Replace home directory with dry run home
                relative_path = expanded_path.sub(home_dir, "")
                File.join(@dry_run_directory, "home", relative_path)
            elsif expanded_path.start_with?("/")
                # Handle absolute paths
                File.join(@dry_run_directory, "system", expanded_path)
            else
                # Relative paths
                File.join(@dry_run_directory, "relative", expanded_path)
            end
        end

        # Check if we're currently in dry run mode
        #
        # @return [Boolean] True if in dry run mode
        def dry_run?
            @dry_run
        end
    end
end

# Load and register built-in adapters and handlers
require_relative "rbdots/adapters/homebrew"
require_relative "rbdots/handlers/shell"
require_relative "rbdots/handlers/git"

# Register built-in components
Rbdots.register_adapter(:homebrew, Rbdots::Adapters::Homebrew)
Rbdots.register_handler(:zsh, Rbdots::Handlers::Shell)
Rbdots.register_handler(:bash, Rbdots::Handlers::Shell)
Rbdots.register_handler(:git, Rbdots::Handlers::Git)
