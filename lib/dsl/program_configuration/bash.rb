# typed: strict
# frozen_string_literal: true

require_relative "base"

module Decldots
    module DSL
        module ProgramConfigs
            # Configuration for bash
            class BashConfiguration < BaseProgramConfiguration
                extend T::Sig

                sig { void }
                def initialize
                    super
                    @aliases = T.let({}, T::Hash[Symbol, String])
                    @environment_variables = T.let({}, T::Hash[Symbol, String])
                end

                sig { params(enabled: T::Boolean).void }
                def enable_completion(enabled: true)
                    @options[:enable_completion] = enabled
                end

                sig { params(name: Symbol, command: String).void }
                def set_alias(name, command)
                    @aliases[name] = command
                end

                sig { params(script: String).void }
                def shell_init(script)
                    @options[:shell_init] = script
                end

                sig { params(name: Symbol, value: String).void }
                def environment_variable(name, value)
                    @environment_variables[name] = value
                end

                sig { returns(T::Hash[Symbol, T.untyped]) }
                def to_hash
                    {
                        **@options,
                        aliases: @aliases,
                        environment_variables: @environment_variables
                    }
                end

                sig { override.void }
                def validate!
                    return if @aliases.any? || @environment_variables.any?

                    raise ValidationError, "Bash configuration must specify at least one alias or environment variable"
                end
            end
        end
    end
end
