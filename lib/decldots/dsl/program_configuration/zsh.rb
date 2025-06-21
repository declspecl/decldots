# typed: strict
# frozen_string_literal: true

require_relative "base"

module Decldots
    module DSL
        module ProgramConfigs
            # Configuration for zsh
            class ZshConfiguration < BaseProgramConfiguration
                extend T::Sig

                sig { void }
                def initialize
                    super
                    @aliases = T.let({}, T::Hash[Symbol, String])
                    @environment_variables = T.let({}, T::Hash[Symbol, String])
                end

                sig { params(enabled: T::Boolean).void }
                def enable_completion(enabled: true)
                    @options[:completion] = enabled
                end

                sig { params(enabled: T::Boolean).void }
                def enable_autosuggestion(enabled: true)
                    @options[:autosuggestion] = enabled
                end

                sig { params(enabled: T::Boolean).void }
                def enable_syntax_highlighting(enabled: true)
                    @options[:syntax_highlighting] = enabled
                end

                sig { params(name: Symbol, command: String).void }
                def set_alias(name, command)
                    @aliases[name] = command
                end

                sig { params(script: String).void }
                def shell_init(script)
                    @options[:shell_init] = script
                end

                sig { params(block: T.proc.bind(OhMyZshConfiguration).void).void }
                def oh_my_zsh(&block)
                    omz_config = OhMyZshConfiguration.new
                    omz_config.instance_eval(&block)
                    @options[:oh_my_zsh] = omz_config.to_hash
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
            end

            class OhMyZshConfiguration
                extend T::Sig

                sig { returns(T::Hash[Symbol, T.untyped]) }
                attr_reader :config

                sig { void }
                def initialize
                    @config = T.let({}, T::Hash[Symbol, T.untyped])
                end

                sig { params(enabled: T::Boolean).void }
                def enable(enabled: true)
                    @config[:enable] = enabled
                end

                sig { params(theme_name: String).void }
                def theme(theme_name)
                    @config[:theme] = theme_name
                end

                sig { params(plugin_list: T::Array[String]).void }
                def plugins(plugin_list)
                    @config[:plugins] = plugin_list
                end

                sig { params(config_text: String).void }
                def extra_config(config_text)
                    @config[:extra_config] = config_text
                end

                sig { returns(T::Hash[Symbol, T.untyped]) }
                def to_hash
                    @config
                end
            end
        end
    end
end
