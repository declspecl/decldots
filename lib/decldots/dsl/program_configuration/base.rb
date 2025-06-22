# typed: strict
# frozen_string_literal: true

module Decldots
    module DSL
        module ProgramConfigs
            # Base configuration class for all program configurations
            class BaseProgramConfiguration
                extend T::Sig
                extend T::Helpers

                abstract!

                sig { returns(T::Hash[Symbol, T.untyped]) }
                attr_reader :options

                sig { void }
                def initialize
                    @options = T.let({}, T::Hash[Symbol, T.untyped])
                end

                sig { params(key: Symbol, value: T.untyped).void }
                def set_option(key, value)
                    @options[key] = value
                end

                sig { returns(T::Boolean) }
                def validate!
                    true
                end

                sig { returns(T::Hash[Symbol, T.untyped]) }
                def to_hash
                    @options
                end
            end
        end
    end
end
