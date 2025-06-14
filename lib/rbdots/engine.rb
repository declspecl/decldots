# typed: strict
# frozen_string_literal: true

require_relative "state_manager"
require_relative "dotfiles_manager"

module Rbdots
    # Core engine for applying configurations
    class Engine
        extend T::Sig

        sig { void }
        def initialize
            @state_manager = T.let(StateManager.new, StateManager)
            @dotfiles_manager = T.let(DotfilesManager.new, DotfilesManager)
        end

        # Apply a configuration to the system
        sig { params(config: Rbdots::DSL::Configuration).returns(T::Boolean) }
        def apply_configuration(config)
            validate_configuration(config)

            # Create checkpoint for rollback
            checkpoint = @state_manager.create_checkpoint

            begin
                apply_packages(config.packages.to_hash) if config.packages&.any?
                apply_programs(config.programs.to_hash) if config.programs&.any?
                apply_dotfiles(config.dotfiles) if config.dotfiles&.any?
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
        sig { params(config: Rbdots::DSL::Configuration).returns(T::Hash[String, T.untyped]) }
        def diff_configuration(config)
            validate_configuration(config)

            changes = T.let({}, T::Hash[String, T.untyped])

            changes["packages"] = diff_packages(config.packages.to_hash) if config.packages&.any?
            changes["programs"] = diff_programs(config.programs.to_hash) if config.programs&.any?
            changes["dotfiles"] = diff_dotfiles(config.dotfiles) if config.dotfiles&.any?

            changes
        end

        # Rollback to a previous checkpoint
        sig { params(checkpoint: String).returns(T::Boolean) }
        def rollback_to_checkpoint(checkpoint)
            @state_manager.rollback_to(checkpoint)
        rescue StandardError => e
            puts "Failed to rollback: #{e.message}"
            false
        end

        private

        # Validate the configuration before applying
        sig { params(config: Rbdots::DSL::Configuration).returns(T::Boolean) }
        def validate_configuration(config)
            raise ValidationError, "Configuration cannot be nil" if config.nil?

            # Additional validation can be added here
            true
        end

        # Apply package configurations
        sig { params(packages: T::Hash[Symbol, T.untyped]).void }
        def apply_packages(packages)
            packages.each do |adapter_name, package_config|
                if Rbdots.dry_run?
                    # In dry run mode, just show what would be done
                    puts "Would configure #{adapter_name} packages:"
                    puts "  Taps: #{package_config.taps.join(", ")}" if package_config.taps.any?
                    if package_config.packages_to_install.any?
                        puts "  Install: #{package_config.packages_to_install.join(", ")}"
                    end
                    puts "  Install casks: #{package_config.casks.join(", ")}" if package_config.casks.any?
                    if package_config.packages_to_uninstall.any?
                        puts "  Uninstall: #{package_config.packages_to_uninstall.join(", ")}"
                    end
                    next
                end

                adapter_class = Rbdots.get_adapter(adapter_name)
                adapter = adapter_class.new

                # Handle Homebrew-specific features using type casting
                if adapter_name == :homebrew
                    homebrew_adapter = T.cast(adapter, Rbdots::Adapters::Homebrew)
                    homebrew_adapter.add_taps(package_config.taps) if package_config.taps.any?
                    homebrew_adapter.install_casks(package_config.casks) if package_config.casks.any?
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
        sig { params(programs: T::Hash[Symbol, T.untyped]).void }
        def apply_programs(programs)
            programs.each do |program_name, program_config|
                handler_class = Rbdots.get_handler(program_name)
                handler = handler_class.new

                puts "Configuring #{program_name}..."
                handler.configure(program_config.options)
            end
        end

        # Apply dotfiles configurations
        sig { params(dotfiles: T.nilable(Rbdots::DSL::Dotfiles)).void }
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
        sig { params(packages: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
        def diff_packages(packages)
            changes = T.let({}, T::Hash[Symbol, T.untyped])

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
        sig { params(programs: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
        def diff_programs(programs)
            changes = T.let({}, T::Hash[Symbol, T.untyped])

            programs.each do |program_name, program_config|
                handler_class = Rbdots.get_handler(program_name)
                handler = handler_class.new

                changes[program_name] = handler.diff_configuration(program_config.options)
            end

            changes
        end

        # Show dotfiles differences
        sig { params(dotfiles: T.nilable(Rbdots::DSL::Dotfiles)).returns(T::Hash[Symbol, T.untyped]) }
        def diff_dotfiles(dotfiles)
            changes = T.let({ links: [] }, T::Hash[Symbol, T.untyped])

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
