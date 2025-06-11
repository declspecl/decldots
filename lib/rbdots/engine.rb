# frozen_string_literal: true

require_relative "state_manager"
require_relative "dotfiles_manager"

module Rbdots
  # Core engine responsible for orchestrating configuration application
  class Engine
    def initialize
      @state_manager = StateManager.new
      @dotfiles_manager = DotfilesManager.new
    end

    # Apply a configuration to the system
    #
    # @param config [Rbdots::DSL::Configuration] The configuration to apply
    # @return [Boolean] True if successful
    def apply_configuration(config)
      validate_configuration(config)

      # Create checkpoint for rollback
      checkpoint = @state_manager.create_checkpoint

      begin
        apply_packages(config.packages) if config.packages
        apply_programs(config.programs) if config.programs
        apply_dotfiles(config.dotfiles) if config.dotfiles

        @state_manager.save_state
        true
      rescue StandardError => e
        puts "Error applying configuration: #{e.message}"
        rollback_to_checkpoint(checkpoint)
        false
      end
    end

    # Show what changes would be applied without actually applying them
    #
    # @param config [Rbdots::DSL::Configuration] The configuration to diff
    # @return [Hash] Hash of changes that would be made
    def diff_configuration(config)
      validate_configuration(config)

      changes = {}

      changes[:packages] = diff_packages(config.packages) if config.packages
      changes[:programs] = diff_programs(config.programs) if config.programs
      changes[:dotfiles] = diff_dotfiles(config.dotfiles) if config.dotfiles

      changes
    end

    # Rollback to a previous checkpoint
    #
    # @param checkpoint [String] The checkpoint identifier
    # @return [Boolean] True if successful
    def rollback_to_checkpoint(checkpoint)
      @state_manager.rollback_to(checkpoint)
    rescue StandardError => e
      puts "Failed to rollback: #{e.message}"
      false
    end

    private

    # Validate the configuration before applying
    #
    # @param config [Rbdots::DSL::Configuration] The configuration to validate
    # @raise [ValidationError] If configuration is invalid
    def validate_configuration(config)
      raise ValidationError, "Configuration cannot be nil" if config.nil?

      # Additional validation can be added here
      true
    end

    # Apply package configurations
    #
    # @param packages [Hash] Package configurations by adapter name
    def apply_packages(packages)
      packages.each do |adapter_name, package_config|
        if Rbdots.dry_run?
          # In dry run mode, just show what would be done
          puts "Would configure #{adapter_name} packages:"
          puts "  Taps: #{package_config.taps.join(", ")}" if package_config.taps.any?
          puts "  Install: #{package_config.packages_to_install.join(", ")}" if package_config.packages_to_install.any?
          puts "  Install casks: #{package_config.casks.join(", ")}" if package_config.casks.any?
          if package_config.packages_to_uninstall.any?
            puts "  Uninstall: #{package_config.packages_to_uninstall.join(", ")}"
          end
          next
        end

        adapter_class = Rbdots.get_adapter(adapter_name)
        adapter = adapter_class.new

        # Handle Homebrew-specific features
        if adapter_name == :homebrew && adapter.respond_to?(:add_taps)
          adapter.add_taps(package_config.taps) if package_config.taps.any?
          adapter.install_casks(package_config.casks) if package_config.casks.any?
        end

        # Install regular packages
        if package_config.packages_to_install.any?
          puts "Installing packages: #{package_config.packages_to_install.join(", ")}"
          adapter.install(package_config.packages_to_install)
        end

        # Uninstall packages
        if package_config.packages_to_uninstall.any?
          puts "Uninstalling packages: #{package_config.packages_to_uninstall.join(", ")}"
          adapter.uninstall(package_config.packages_to_uninstall)
        end
      end
    end

    # Apply program configurations
    #
    # @param programs [Hash] Program configurations by handler name
    def apply_programs(programs)
      programs.each do |program_name, program_config|
        handler_class = Rbdots.get_handler(program_name)
        handler = handler_class.new

        puts "Configuring #{program_name}..."
        handler.configure(program_config.options)
      end
    end

    # Apply dotfiles configurations
    #
    # @param dotfiles [Rbdots::DSL::Dotfiles] Dotfiles configuration
    def apply_dotfiles(dotfiles)
      dotfiles.links.each do |link_config|
        puts "Linking dotfile: #{link_config[:name]} (mutable: #{link_config[:mutable]})"
        @dotfiles_manager.link_config(
          link_config[:name],
          mutable: link_config[:mutable],
          source_directory: dotfiles.source_directory
        )
      end
    end

    # Show package differences
    #
    # @param packages [Hash] Package configurations
    # @return [Hash] Package differences
    def diff_packages(packages)
      changes = {}

      packages.each do |adapter_name, package_config|
        adapter_class = Rbdots.get_adapter(adapter_name)
        adapter = adapter_class.new

        to_install = package_config.packages_to_install.reject { |pkg| adapter.installed?(pkg) }
        to_uninstall = package_config.packages_to_uninstall.select { |pkg| adapter.installed?(pkg) }

        changes[adapter_name] = {
          install: to_install,
          uninstall: to_uninstall
        }
      end

      changes
    end

    # Show program configuration differences
    #
    # @param programs [Hash] Program configurations
    # @return [Hash] Program differences
    def diff_programs(programs)
      changes = {}

      programs.each do |program_name, program_config|
        handler_class = Rbdots.get_handler(program_name)
        handler = handler_class.new

        changes[program_name] = handler.diff_configuration(program_config.options)
      end

      changes
    end

    # Show dotfiles differences
    #
    # @param dotfiles [Rbdots::DSL::Dotfiles] Dotfiles configuration
    # @return [Hash] Dotfiles differences
    def diff_dotfiles(dotfiles)
      changes = { links: [] }

      dotfiles.links.each do |link_config|
        diff = @dotfiles_manager.diff_link(
          link_config[:name],
          mutable: link_config[:mutable],
          source_directory: dotfiles.source_directory
        )
        changes[:links] << diff if diff[:action] != :no_change
      end

      changes
    end
  end
end
