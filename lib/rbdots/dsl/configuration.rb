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

            sig { returns(Rbdots::DSL::Packages) }
            attr_reader :packages

            sig { returns(Rbdots::DSL::Programs) }
            attr_reader :programs

            sig { returns(T.nilable(Rbdots::DSL::Dotfiles)) }
            attr_reader :dotfiles

            sig { returns(Rbdots::DSL::UserConfiguration) }
            attr_reader :user_config

            sig { void }
            def initialize
                @packages = T.let(Packages.new({}), Rbdots::DSL::Packages)
                @programs = T.let(Programs.new({}), Rbdots::DSL::Programs)
                @dotfiles = T.let(nil, T.nilable(Rbdots::DSL::Dotfiles))
                @user_config = T.let(UserConfiguration.new, Rbdots::DSL::UserConfiguration)
            end

            # Configure user information
            sig { params(block: T.nilable(T.proc.params(user: Rbdots::DSL::UserConfiguration).void)).void }
            def user(&block)
                @user_config_obj = T.let(UserConfiguration.new, Rbdots::DSL::UserConfiguration)
                block&.call(@user_config_obj)
                @user_config = @user_config_obj.to_hash
            end

            # Configure packages for various package managers
            sig { returns(T.nilable(Rbdots::DSL::Packages)) }
            def packages
                @packages_dsl = T.let(@packages_dsl ||= Rbdots::DSL::Packages.new(@packages), Rbdots::DSL::Packages)
            end

            # Configure programs
            sig { returns(T.nilable(Rbdots::DSL::Programs)) }
            def programs
                @programs_dsl = T.let(@programs_dsl ||= Rbdots::DSL::Programs.new(@programs), Rbdots::DSL::Programs)
            end

            # Configure dotfiles linking
            sig do
                params(block: T.nilable(T.proc.params(dotfiles: Rbdots::DSL::Dotfiles).void)).returns(T.nilable(Rbdots::DSL::Dotfiles))
            end
            def dotfiles(&block)
                @dotfiles = Rbdots::DSL::Dotfiles.new
                block&.call(@dotfiles)
                @dotfiles
            end

            # Validate the entire configuration
            #
            # @return [Boolean] True if valid
            # @raise [ValidationError] If configuration is invalid
            sig { returns(T::Boolean) }
            def validate!
                validate_packages!
                validate_programs!
                validate_dotfiles!
                true
            end

            private

            # Validate package configurations
            sig { void }
            def validate_packages!
                @packages.each do |adapter_name, package_config|
                    unless Rbdots.adapters.key?(adapter_name)
                        raise ValidationError, 
                              "Unknown package manager: #{adapter_name}"
                    end

                    package_config.validate!
                end
            end

            # Validate program configurations
            sig { void }
            def validate_programs!
                @programs.each do |program_name, program_config|
                    unless Rbdots.handlers.key?(program_name)
                        raise ValidationError, 
                              "Unknown program handler: #{program_name}"
                    end

                    program_config.validate!
                end
            end

            # Validate dotfiles configuration
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

            # Set user name
            #
            # @param name [String] The user's name
            sig { params(name: String).void }
            def name(name)
                @config[:name] = name
            end

            # Set user email
            #
            # @param email [String] The user's email
            sig { params(email: String).void }
            def email(email)
                @config[:email] = email
            end

            # Set home directory
            #
            # @param directory [String] The home directory path
            sig { params(directory: String).void }
            def home_directory(directory)
                @config[:home_directory] = File.expand_path(directory)
            end

            # Convert to hash
            #
            # @return [Hash] The configuration as a hash
            sig { returns(T::Hash[Symbol, T.untyped]) }
            def to_hash
                @config
            end
        end
    end
end
