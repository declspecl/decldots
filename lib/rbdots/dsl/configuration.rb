# typed: strict
# frozen_string_literal: true

require_relative "packages"
require_relative "programs"
require_relative "dotfiles"

module Rbdots
    module DSL
        # Main configuration class that provides the DSL interface
        class Configuration
            extend T::Sig

            sig { returns(T::Hash[Symbol, T.untyped]) }
            attr_reader :packages_config

            sig { returns(T::Hash[Symbol, T.untyped]) }
            attr_reader :programs_config

            sig { returns(Rbdots::DSL::UserConfiguration) }
            attr_reader :user_config

            sig { void }
            def initialize
                @packages_config = T.let({}, T::Hash[Symbol, T.untyped])
                @programs_config = T.let({}, T::Hash[Symbol, T.untyped])
                @dotfiles = T.let(nil, T.nilable(Rbdots::DSL::Dotfiles))
                @user_config = T.let(UserConfiguration.new, Rbdots::DSL::UserConfiguration)
                @packages = T.let(nil, T.nilable(Rbdots::DSL::Packages))
                @programs = T.let(nil, T.nilable(Rbdots::DSL::Programs))
            end

            sig { params(block: T.nilable(T.proc.void)).void }
            def user(&block)
                user_config_obj = UserConfiguration.new
                user_config_obj.instance_eval(&block) if block
                @user_config = user_config_obj
            end

            sig { returns(Rbdots::DSL::Packages) }
            def packages
                @packages ||= Rbdots::DSL::Packages.new(@packages_config)
            end

            sig { returns(Rbdots::DSL::Programs) }
            def programs
                @programs ||= Rbdots::DSL::Programs.new(@programs_config)
            end

            sig { params(block: T.nilable(T.proc.void)).returns(Rbdots::DSL::Dotfiles) }
            def dotfiles(&block)
                @dotfiles = Rbdots::DSL::Dotfiles.new
                @dotfiles.instance_eval(&block) if block
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
                @packages_config.each do |package_manager_name, package_config|
                    unless Rbdots.package_managers.key?(package_manager_name)
                        raise ValidationError, 
                              "Unknown package manager: #{package_manager_name}"
                    end

                    package_config.validate!
                end
            end

            sig { void }
            def validate_programs!
                @programs_config.each do |program_name, program_config|
                    unless Rbdots.programs.key?(program_name)
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
