# typed: strict
# frozen_string_literal: true

require_relative "program_configuration/base"
require_relative "program_configuration/zsh"
require_relative "program_configuration/git"

module Rbdots
    module DSL
        # Program configuration DSL interface
        class Programs
            extend T::Sig

            sig { returns(T::Hash[Symbol, ProgramConfigs::BaseProgramConfiguration]) }
            attr_reader :programs

            sig { params(programs_hash: T::Hash[Symbol, T.untyped]).void }
            def initialize(programs_hash = {})
                @programs = T.let(programs_hash, T::Hash[Symbol, ProgramConfigs::BaseProgramConfiguration])
            end

            sig { params(block: T.nilable(T.proc.bind(ProgramConfigs::ZshConfiguration).void)).void }
            def zsh(&block)
                config = ProgramConfigs::ZshConfiguration.new
                config.instance_eval(&block) if block_given?
                @programs[:zsh] = config
            end

            sig { params(block: T.nilable(T.proc.bind(ProgramConfigs::GitConfiguration).void)).void }
            def git(&block)
                config = ProgramConfigs::GitConfiguration.new
                config.instance_eval(&block) if block_given?
                @programs[:git] = config
            end
        end
    end
end
