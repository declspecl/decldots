# typed: strict
# frozen_string_literal: true

require "fileutils"
require "sorbet-runtime"
require_relative "rbdots/version"

# Main namespace for the Rbdots declarative dotfile management framework
module Rbdots
    extend T::Sig

    class Error < StandardError; end
    class ConfigurationError < Error; end
    class ValidationError < Error; end
end

require_relative "rbdots/package_managers/base"
require_relative "rbdots/programs/base"
require_relative "rbdots/engine"
require_relative "rbdots/dsl/configuration"

module Rbdots
    @package_managers = T.let({}, T::Hash[Symbol, T.class_of(Rbdots::PackageManagers::Base)])
    @programs = T.let({}, T::Hash[Symbol, T.class_of(Rbdots::Programs::Base)])
    @dry_run = T.let(false, T::Boolean)
    @dry_run_directory = T.let(nil, T.nilable(String))

    class << self
        extend T::Sig

        sig { returns(T::Hash[Symbol, T.class_of(Rbdots::PackageManagers::Base)]) }
        attr_reader :package_managers

        sig { returns(T::Hash[Symbol, T.class_of(Rbdots::Programs::Base)]) }
        attr_reader :programs

        sig { returns(T::Boolean) }
        attr_reader :dry_run

        sig { returns(T.nilable(String)) }
        attr_reader :dry_run_directory

        sig do 
            params(
                block: T.nilable(T.proc.params(config: Rbdots::DSL::Configuration).void)
            ).returns(Rbdots::DSL::Configuration) 
        end
        def configure(&block)
            config = DSL::Configuration.new
            block&.call(config)
            config
        end

        sig { params(config: Rbdots::DSL::Configuration).returns(T::Boolean) }
        def apply(config)
            engine = Engine.new
            engine.apply_configuration(config)
        end

        sig { params(config: Rbdots::DSL::Configuration).returns(T::Hash[String, T.untyped]) }
        def diff(config)
            engine = Engine.new
            engine.diff_configuration(config)
        end

        sig { params(name: Symbol, manager_class: T.class_of(Rbdots::PackageManagers::Base)).void }
        def register_package_manager(name, manager_class)
            @package_managers[name] = manager_class
        end

        sig { params(name: Symbol).returns(T.class_of(Rbdots::PackageManagers::Base)) }
        def get_package_manager(name)
            @package_managers[name] || raise(ConfigurationError, "Unknown package manager: #{name}")
        end

        sig { params(name: Symbol, program_class: T.class_of(Rbdots::Programs::Base)).void }
        def register_program(name, program_class)
            @programs[name] = program_class
        end

        sig { params(name: Symbol).returns(T.class_of(Rbdots::Programs::Base)) }
        def get_program(name)
            @programs[name] || raise(ConfigurationError, "Unknown program: #{name}")
        end

        sig { params(enabled: T::Boolean, temp_dir: T.nilable(String)).void }
        def enable_dry_run(enabled = true, temp_dir: nil)
            @dry_run = enabled

            if enabled
                setup_dry_run_environment(temp_dir)
            else
                teardown_dry_run_environment
            end
        end

        sig { void }
        def disable_dry_run
            enable_dry_run(false)
        end

        sig { returns(T::Boolean) }
        def dry_run?
            @dry_run
        end

        sig { params(real_path: String).returns(String) }
        def dry_run_path(real_path)
            return real_path unless @dry_run

            expanded_path = File.expand_path(real_path)
            home_dir = File.expand_path("~")

            if expanded_path.start_with?(home_dir)
                relative_path = expanded_path.sub(home_dir, "")
                File.join(T.must(@dry_run_directory), "home", relative_path)
            elsif expanded_path.start_with?("/")
                File.join(T.must(@dry_run_directory), "system", expanded_path)
            else
                File.join(T.must(@dry_run_directory), "relative", expanded_path)
            end
        end

        private

        sig { params(temp_dir: T.nilable(String)).void }
        def setup_dry_run_environment(temp_dir)
            require "tmpdir"
            @dry_run_directory = temp_dir || Dir.mktmpdir("rbdots_dry_run_")
            puts "Dry run mode enabled. Files will be created in: #{@dry_run_directory}"

            FileUtils.mkdir_p(File.join(@dry_run_directory, "home"))
            FileUtils.mkdir_p(File.join(@dry_run_directory, "config"))
        end

        sig { void }
        def teardown_dry_run_environment
            @dry_run_directory = nil
            puts "Dry run mode disabled."
        end
    end
end

require_relative "rbdots/package_managers/homebrew"
require_relative "rbdots/programs/shell"
require_relative "rbdots/programs/git"

Rbdots.register_package_manager(:homebrew, Rbdots::PackageManagers::Homebrew)
Rbdots.register_program(:zsh, Rbdots::Programs::Shell)
Rbdots.register_program(:bash, Rbdots::Programs::Shell)
Rbdots.register_program(:git, Rbdots::Programs::Git)
