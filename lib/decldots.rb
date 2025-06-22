# typed: strict
# frozen_string_literal: true

require "fileutils"
require "sorbet-runtime"
require_relative "version"

module Decldots
    extend T::Sig

    class Error < StandardError; end
    class ConfigurationError < Error; end
    class ValidationError < Error; end
end

require_relative "core/engine"
require_relative "core/package_managers/base"
require_relative "core/programs/base"
require_relative "dsl/configuration"

module Decldots
    @package_managers = T.let({}, T::Hash[Symbol, T.class_of(Decldots::PackageManagers::Base)])
    @programs = T.let({}, T::Hash[Symbol, T.class_of(Decldots::Programs::Base)])

    class << self
        extend T::Sig

        sig { returns(String) }
        attr_reader :source_directory

        sig { returns(T::Hash[Symbol, T.class_of(Decldots::PackageManagers::Base)]) }
        attr_reader :package_managers

        sig { returns(T::Hash[Symbol, T.class_of(Decldots::Programs::Base)]) }
        attr_reader :programs

        sig { params(source_directory: String).void }
        def initialize(source_directory)
            @source_directory = T.let(source_directory, String)
            @engine = T.let(Decldots::Engine.new(source_directory), Decldots::Engine)
        end

        sig do 
            params(
                block: T.nilable(T.proc.params(config: Decldots::DSL::Configuration).void)
            ).returns(Decldots::DSL::Configuration) 
        end
        def configure(&block)
            config = DSL::Configuration.new
            block&.call(config)
            config
        end

        sig { params(config: Decldots::DSL::Configuration).returns(T::Boolean) }
        def apply(config)
            @engine.apply_configuration(config)
        end

        sig { params(config: Decldots::DSL::Configuration).returns(T::Hash[String, T.untyped]) }
        def diff(config)
            @engine.diff_configuration(config)
        end

        sig { params(name: Symbol, manager_class: T.class_of(Decldots::PackageManagers::Base)).void }
        def register_package_manager(name, manager_class)
            @package_managers[name] = manager_class
        end

        sig { params(name: Symbol).returns(T.class_of(Decldots::PackageManagers::Base)) }
        def get_package_manager(name)
            @package_managers[name] || raise(ConfigurationError, "Unknown package manager: #{name}")
        end

        sig { params(name: Symbol, program_class: T.class_of(Decldots::Programs::Base)).void }
        def register_program(name, program_class)
            @programs[name] = program_class
        end

        sig { params(name: Symbol).returns(T.class_of(Decldots::Programs::Base)) }
        def get_program(name)
            @programs[name] || raise(ConfigurationError, "Unknown program: #{name}")
        end
    end
end

require_relative "core/package_managers/homebrew"
require_relative "core/programs/zsh"
require_relative "core/programs/bash"
require_relative "core/programs/git"

Decldots.register_package_manager(:homebrew, Decldots::PackageManagers::Homebrew)
Decldots.register_program(:zsh, Decldots::Programs::Zsh)
Decldots.register_program(:bash, Decldots::Programs::Bash)
Decldots.register_program(:git, Decldots::Programs::Git)
