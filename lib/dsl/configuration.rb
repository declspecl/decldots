# typed: strict
# frozen_string_literal: true

require_relative "package_managers"
require_relative "programs"
require_relative "program_configuration/base"
require_relative "dotfiles"

module Decldots
    module DSL
        # Main configuration class that provides the DSL interface
        class Configuration
            extend T::Sig

            sig { returns(Decldots::DSL::PackageManagers) }
            attr_reader :package_managers

            sig { returns(Decldots::DSL::Programs) }
            attr_reader :programs

            sig { void }
            def initialize
                @dotfiles = T.let(Dotfiles.new, Decldots::DSL::Dotfiles)
                @package_managers = T.let(PackageManagers.new, Decldots::DSL::PackageManagers)
                @programs = T.let(Programs.new, Decldots::DSL::Programs)
            end

            sig { params(block: T.nilable(T.proc.bind(Decldots::DSL::Dotfiles).void)).returns(Decldots::DSL::Dotfiles) }
            def dotfiles(&block)
                @dotfiles.instance_eval(&block) if block
                @dotfiles
            end

            sig { returns(T::Boolean) }
            def validate!
                validate_package_managers!
                validate_programs!
                validate_dotfiles!
                true
            end

            private

            sig { void }
            def validate_package_managers!
                @package_managers.package_managers.each do |package_manager_name, package_config|
                    unless Decldots.package_managers.key?(package_manager_name)
                        raise ValidationError, 
                              "Unknown package manager: #{package_manager_name}"
                    end

                    package_config.validate!
                end
            end

            sig { void }
            def validate_programs!
                @programs.programs.each do |program_name, program_config|
                    unless Decldots.programs.key?(program_name)
                        raise ValidationError, 
                              "Unknown program program: #{program_name}"
                    end

                    program_config.validate!
                end
            end

            sig { void }
            def validate_dotfiles!
                @dotfiles.validate!
            end
        end
    end
end
