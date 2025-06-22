# typed: strict
# frozen_string_literal: true

require_relative "state_manager"
require_relative "dotfiles_manager"

module Decldots
    # Core engine for applying configurations
    class Engine
        extend T::Sig

        sig { returns(Decldots::StateManager) }
        attr_reader :state_manager

        sig { returns(Decldots::DotfilesManager) }
        attr_reader :dotfiles_manager

        sig { params(source_directory: String).void }
        def initialize(source_directory)
            @state_manager = T.let(Decldots::StateManager.new, Decldots::StateManager)
            @dotfiles_manager = T.let(Decldots::DotfilesManager.new(source_directory), Decldots::DotfilesManager)
        end

        sig { params(config: Decldots::DSL::Configuration).returns(T::Boolean) }
        def apply_configuration(config)
            validate_configuration!(config)

            checkpoint = @state_manager.create_checkpoint

            begin
                apply_packages(config.package_managers.package_managers) if config.package_managers.package_managers.any?
                apply_programs(config.programs.programs) if config.programs.programs.any?
                apply_dotfiles(config.dotfiles) if config.dotfiles

                @state_manager.save_state
                true
            rescue StandardError => e
                puts "Error applying configuration: #{e.message}"
                rollback_to_checkpoint(checkpoint)
                false
            end
        end

        sig { params(config: Decldots::DSL::Configuration).returns(T::Hash[String, T.untyped]) }
        def diff_configuration(config)
            validate_configuration!(config)

            changes = T.let({}, T::Hash[String, T.untyped])

            if config.package_managers.package_managers.any?
                changes["packages"] = 
                    diff_packages(config.package_managers.package_managers)
            end
            changes["programs"] = diff_programs(config.programs.programs) if config.programs.programs.any?
            changes["dotfiles"] = diff_dotfiles(config.dotfiles) if config.dotfiles

            changes
        end

        sig { params(checkpoint: String).returns(T::Boolean) }
        def rollback_to_checkpoint(checkpoint)
            @state_manager.rollback_to(checkpoint)
        rescue StandardError => e
            puts "Failed to rollback: #{e.message}"
            false
        end

        private

        sig { params(config: Decldots::DSL::Configuration).void }
        def validate_configuration!(config)
            raise ValidationError, "Configuration cannot be nil" if config.nil?
        end

        sig do
            params(packages: T::Hash[Symbol, 
                                     Decldots::DSL::PackageManagerConfigs::BasePackageManagerConfiguration]
                  ).void
        end
        def apply_packages(packages)
            packages.each do |package_manager_name, package_config|
                manager_class = Decldots.get_package_manager(package_manager_name)
                manager = manager_class.new

                if package_manager_name == :homebrew
                    homebrew_manager = T.cast(manager, Decldots::PackageManagers::Homebrew)
                    homebrew_config = T.cast(package_config, 
                                             Decldots::DSL::PackageManagerConfigs::HomebrewConfiguration
                                            )
                    homebrew_manager.add_taps(homebrew_config.taps) if homebrew_config.taps.any?
                    homebrew_manager.install_casks(homebrew_config.casks) if homebrew_config.casks.any?
                end

                if package_config.packages_to_install.any?
                    puts "Installing packages: #{package_config.packages_to_install.join(", ")}"
                    manager.install(package_config.packages_to_install)
                end

                if package_config.packages_to_uninstall.any?
                    puts "Uninstalling packages: #{package_config.packages_to_uninstall.join(", ")}"
                    manager.uninstall(package_config.packages_to_uninstall)
                end
            end
        end

        sig { params(programs: T::Hash[Symbol, Decldots::DSL::ProgramConfigs::BaseProgramConfiguration]).void }
        def apply_programs(programs)
            programs.each do |program_name, program_config|
                program_class = Decldots.get_program(program_name)
                program = program_class.new

                puts "Configuring #{program_name}..."
                program.configure(program_config.options)
            end
        end

        sig { params(dotfiles: T.nilable(Decldots::DSL::Dotfiles)).void }
        def apply_dotfiles(dotfiles)
            return unless dotfiles

            dotfiles.links.each do |link_config|
                puts "Linking dotfile: #{link_config[:name]} (mutable: #{link_config[:mutable]})"
                @dotfiles_manager.link_config(
                    link_config[:name],
                    link_config[:mutable],
                    link_config[:source_directory],
                    link_config[:target]
                )
            end
        end

        sig do
            params(packages: T::Hash[Symbol, 
                                     Decldots::DSL::PackageManagerConfigs::BasePackageManagerConfiguration]
                  ).returns(T::Hash[Symbol, 
                                    T.untyped]
                           )
        end
        def diff_packages(packages)
            changes = T.let({}, T::Hash[Symbol, T.untyped])

            packages.each do |package_manager_name, package_config|
                manager_class = Decldots.get_package_manager(package_manager_name)
                manager = manager_class.new

                to_install = package_config.packages_to_install.reject { |pkg| manager.installed?(pkg) }
                to_uninstall = package_config.packages_to_uninstall.select { |pkg| manager.installed?(pkg) }

                changes[package_manager_name] = {
                    install: to_install,
                    uninstall: to_uninstall
                }
            end

            changes
        end

        sig do
            params(programs: T::Hash[Symbol, 
                                     Decldots::DSL::ProgramConfigs::BaseProgramConfiguration]
                  ).returns(T::Hash[Symbol, 
                                    T.untyped]
                           )
        end
        def diff_programs(programs)
            changes = T.let({}, T::Hash[Symbol, T.untyped])

            programs.each do |program_name, program_config|
                program_class = Decldots.get_program(program_name)
                program = program_class.new

                changes[program_name] = program.diff_configuration(program_config.options)
            end

            changes
        end

        sig { params(dotfiles: T.nilable(Decldots::DSL::Dotfiles)).returns(T::Hash[Symbol, T.untyped]) }
        def diff_dotfiles(dotfiles)
            changes = T.let({ links: [] }, T::Hash[Symbol, T.untyped])

            return changes unless dotfiles

            dotfiles.links.each do |link_config|
                diff = @dotfiles_manager.diff_link(
                    link_config[:name],
                    mutable: link_config[:mutable],
                    source_directory: Decldots.source_directory
                )
                changes[:links] << diff if diff[:action] != :no_change
            end

            changes
        end
    end
end
