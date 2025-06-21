# typed: strict
# frozen_string_literal: true

require_relative "packages"
require_relative "programs"
require_relative "program_configuration/base"
require_relative "dotfiles"

module Decldots
    module DSL
        # Main configuration class that provides the DSL interface
        class Configuration
            extend T::Sig

            sig { returns(T::Hash[Symbol, T.untyped]) }
            attr_reader :packages_config

            sig { returns(T::Hash[Symbol, T.untyped]) }
            attr_reader :programs_config

            sig { returns(Decldots::DSL::UserConfiguration) }
            attr_reader :user_config

            sig { returns(T.nilable(Decldots::DSL::Dotfiles)) }
            attr_reader :dotfiles_config

            sig { void }
            def initialize
                @packages_config = T.let({}, T::Hash[Symbol, T.untyped])
                @programs_config = T.let({}, T::Hash[Symbol, T.untyped])
                @dotfiles = T.let(nil, T.nilable(Decldots::DSL::Dotfiles))
                @dotfiles_config = T.let(nil, T.nilable(Decldots::DSL::Dotfiles))
                @user_config = T.let(UserConfiguration.new, Decldots::DSL::UserConfiguration)
                @packages = T.let(nil, T.nilable(Decldots::DSL::PackageManagement))
                @programs = T.let(nil, T.nilable(Decldots::DSL::Programs))
            end

            sig { params(block: T.nilable(T.proc.bind(Decldots::DSL::UserConfiguration).void)).void }
            def user(&block)
                user_config_obj = UserConfiguration.new
                user_config_obj.instance_eval(&block) if block
                @user_config = user_config_obj
            end

            sig { returns(Decldots::DSL::PackageManagement) }
            def packages
                @packages ||= Decldots::DSL::PackageManagement.new
            end

            sig { returns(Decldots::DSL::Programs) }
            def programs
                @programs ||= Decldots::DSL::Programs.new
            end

            sig { params(block: T.nilable(T.proc.bind(Decldots::DSL::Dotfiles).void)).returns(Decldots::DSL::Dotfiles) }
            def dotfiles(&block)
                @dotfiles = Decldots::DSL::Dotfiles.new
                @dotfiles.instance_eval(&block) if block
                @dotfiles_config = @dotfiles
                @dotfiles
            end

            sig { returns(T::Boolean) }
            def validate!
                validate_packages!
                validate_programs!
                validate_dotfiles!
                true
            end

            private

            sig { void }
            def validate_packages!
                return unless @packages

                @packages.packages.each do |package_manager_name, package_config|
                    unless Decldots.package_managers.key?(package_manager_name)
                        raise ValidationError, 
                              "Unknown package manager: #{package_manager_name}"
                    end

                    package_config.validate!
                end
            end

            sig { void }
            def validate_programs!
                return unless @programs

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
                @dotfiles&.validate!
            end
        end

        # User configuration helper class
        class UserConfiguration
            extend T::Sig

            sig { returns(T::Hash[Symbol, T.untyped]) }
            attr_reader :config

            sig { void }
            def initialize
                @config = T.let({}, T::Hash[Symbol, T.untyped])
            end

            sig { params(name: String).void }
            def name(name)
                @config[:name] = name
            end

            sig { params(email: String).void }
            def email(email)
                @config[:email] = email
            end

            sig { params(directory: String).void }
            def home_directory(directory)
                @config[:home_directory] = File.expand_path(directory)
            end

            sig { returns(T::Hash[Symbol, T.untyped]) }
            def to_hash
                @config
            end
        end
    end
end
