# typed: strict
# frozen_string_literal: true

require_relative "program_configuration/base"
require_relative "program_configuration/zsh"
require_relative "program_configuration/bash"
require_relative "program_configuration/git"
require_relative "program_configuration/vim"
require_relative "program_configuration/ssh"
require_relative "program_configuration/tmux"

module Decldots
    module DSL
        # Program configuration DSL interface
        class Programs
            extend T::Sig

            sig { returns(T::Hash[Symbol, ProgramConfigs::BaseProgramConfiguration]) }
            attr_reader :programs

            sig { void }
            def initialize
                @programs = T.let({}, T::Hash[Symbol, ProgramConfigs::BaseProgramConfiguration])
            end

            sig { params(block: T.proc.bind(ProgramConfigs::ZshConfiguration).void).void }
            def zsh(&block)
                config = ProgramConfigs::ZshConfiguration.new
                config.instance_eval(&block)
                @programs[:zsh] = config
                Decldots.register_program(:zsh, Decldots::Programs::Zsh)
            end

            sig { params(block: T.proc.bind(ProgramConfigs::BashConfiguration).void).void }
            def bash(&block)
                config = ProgramConfigs::BashConfiguration.new
                config.instance_eval(&block)
                @programs[:bash] = config
                Decldots.register_program(:bash, Decldots::Programs::Bash)
            end

            sig { params(block: T.proc.bind(ProgramConfigs::GitConfiguration).void).void }
            def git(&block)
                config = ProgramConfigs::GitConfiguration.new
                config.instance_eval(&block)
                @programs[:git] = config
                Decldots.register_program(:git, Decldots::Programs::Git)
            end

            sig { params(block: T.proc.bind(ProgramConfigs::VimConfiguration).void).void }
            def vim(&block)
                config = ProgramConfigs::VimConfiguration.new
                config.instance_eval(&block)
                @programs[:vim] = config
                Decldots.register_program(:vim, Decldots::Programs::Vim)
            end

            sig { params(block: T.proc.bind(ProgramConfigs::SshConfiguration).void).void }
            def ssh(&block)
                config = ProgramConfigs::SshConfiguration.new
                config.instance_eval(&block)
                @programs[:ssh] = config
                Decldots.register_program(:ssh, Decldots::Programs::Ssh)
            end

            sig { params(block: T.proc.bind(ProgramConfigs::TmuxConfiguration).void).void }
            def tmux(&block)
                config = ProgramConfigs::TmuxConfiguration.new
                config.instance_eval(&block)
                @programs[:tmux] = config
                Decldots.register_program(:tmux, Decldots::Programs::Tmux)
            end
        end
    end
end
