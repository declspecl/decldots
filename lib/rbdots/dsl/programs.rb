# typed: strict
# frozen_string_literal: true

module Rbdots
    module DSL
        # Program configuration DSL interface
        class Programs
            extend T::Sig

            sig { params(programs_hash: T::Hash[Symbol, T.untyped]).void }
            def initialize(programs_hash)
                @programs = programs_hash
            end

            # Configure zsh shell
            #
            # @yield [zsh] Zsh configuration block
            sig { params(block: T.nilable(T.proc.params(config: ProgramConfiguration).void)).void }
            def zsh
                config = ProgramConfiguration.new
                yield(config) if block_given?
                @programs[:zsh] = config
            end

            # Configure bash shell
            #
            # @yield [bash] Bash configuration block
            sig { params(block: T.nilable(T.proc.params(config: ProgramConfiguration).void)).void }
            def bash
                config = ProgramConfiguration.new
                yield(config) if block_given?
                @programs[:bash] = config
            end

            # Configure git
            #
            # @yield [git] Git configuration block
            sig { params(block: T.nilable(T.proc.params(config: ProgramConfiguration).void)).void }
            def git
                config = ProgramConfiguration.new
                yield(config) if block_given?
                @programs[:git] = config
            end

            # Configure VSCode
            #
            # @yield [vscode] VSCode configuration block
            sig { params(block: T.nilable(T.proc.params(config: ProgramConfiguration).void)).void }
            def vscode
                config = ProgramConfiguration.new
                yield(config) if block_given?
                @programs[:vscode] = config
            end
        end

        # Configuration for a specific program
        class ProgramConfiguration
            extend T::Sig

            sig { returns(T::Hash[Symbol, T.untyped]) }
            attr_reader :options

            sig { void }
            def initialize
                @options = T.let({}, T::Hash[Symbol, T.untyped])
            end

            # Enable completion (shell specific)
            #
            # @param enabled [Boolean] Whether to enable completion
            sig { params(enabled: T.nilable(T::Boolean)).void }
            def enable_completion(enabled: true)
                @options[:enable_completion] = enabled
            end

            # Enable autosuggestion (shell specific)
            #
            # @param enabled [Boolean] Whether to enable autosuggestion
            sig { params(enabled: T.nilable(T::Boolean)).void }
            def enable_autosuggestion(enabled: true)
                @options[:enable_autosuggestion] = enabled
            end

            # Enable syntax highlighting (shell specific)
            #
            # @param enabled [Boolean] Whether to enable syntax highlighting
            sig { params(enabled: T.nilable(T::Boolean)).void }
            def enable_syntax_highlighting(enabled: true)
                @options[:enable_syntax_highlighting] = enabled
            end

            # Configure shell aliases
            #
            # @yield [aliases] Aliases configuration block
            sig { params(block: T.nilable(T.proc.params(config: AliasesConfiguration).void)).void }
            def aliases
                aliases_config = AliasesConfiguration.new
                yield(aliases_config) if block_given?
                @options[:aliases] = aliases_config.to_hash
            end

            # Set shell initialization script
            #
            # @param script [String] The shell script to run on initialization
            sig { params(script: String).void }
            def shell_init(script)
                @options[:shell_init] = script
            end

            # Configure Oh My Zsh (zsh specific)
            #
            # @yield [omz] Oh My Zsh configuration block
            sig { params(block: T.nilable(T.proc.params(config: OhMyZshConfiguration).void)).void }
            def oh_my_zsh
                omz_config = OhMyZshConfiguration.new
                yield(omz_config) if block_given?
                @options[:oh_my_zsh] = omz_config.to_hash
            end

            # Set git user name
            #
            # @param name [String] The git user name
            sig { params(name: String).void }
            def user_name(name)
                @options[:user_name] = name
            end

            # Set git user email
            #
            # @param email [String] The git user email
            sig { params(email: String).void }
            def user_email(email)
                @options[:user_email] = email
            end

            # Set git default branch
            #
            # @param branch [String] The default branch name
            sig { params(branch: String).void }
            def default_branch(branch)
                @options[:default_branch] = branch
            end

            # Set git pull behavior
            #
            # @param enabled [Boolean] Whether to rebase on pull
            sig { params(enabled: T.nilable(T::Boolean)).void }
            def pull_rebase(enabled = true)
                @options[:pull_rebase] = enabled
            end

            # Set environment variables
            #
            # @param vars [Hash] Hash of environment variable name/value pairs
            sig { params(vars: T::Hash[Symbol, T.untyped]).void }
            def environment_variables(vars)
                @options[:environment_variables] = vars
            end

            # Set a generic option
            #
            # @param key [Symbol] The option key
            # @param value [Object] The option value
            sig { params(key: Symbol, value: T.untyped).void }
            def set_option(key, value)
                @options[key] = value
            end

            # Validate the program configuration
            #
            # @return [Boolean] True if valid
            # @raise [ValidationError] If configuration is invalid
            sig { returns(T::Boolean) }
            def validate!
                # Basic validation - can be extended per program type
                true
            end
        end

        # Helper class for configuring shell aliases
        class AliasesConfiguration
            extend T::Sig

            sig { returns(T::Hash[Symbol, T.untyped]) }
            attr_reader :aliases

            sig { void }
            def initialize
                @aliases = T.let({}, T::Hash[Symbol, T.untyped])
            end

            # Set an alias
            #
            # @param name [String, Symbol] The alias name
            # @param command [String] The command to alias to
            sig { params(name: Symbol, command: T.nilable(String)).void }
            def method_missing(name, command = nil)
                if command
                    @aliases[name] = command
                else
                    super
                end
            end

            # Check if we respond to a method (for alias setting)
            sig { params(_name: Symbol, _include_private: T::Boolean).returns(T::Boolean) }
            def respond_to_missing?(_name, _include_private = false)
                true
            end

            # Convert to hash
            #
            # @return [Hash] The aliases as a hash
            sig { returns(T::Hash[Symbol, T.untyped]) }
            def to_hash
                @aliases
            end
        end

        # Helper class for configuring Oh My Zsh
        class OhMyZshConfiguration
            extend T::Sig

            sig { returns(T::Hash[Symbol, T.untyped]) }
            attr_reader :config

            sig { void }
            def initialize
                @config = T.let({}, T::Hash[Symbol, T.untyped])
            end

            # Enable Oh My Zsh
            #
            # @param enabled [Boolean] Whether to enable Oh My Zsh
            sig { params(enabled: T.nilable(T::Boolean)).void }
            def enable(enabled: true)
                @config[:enable] = enabled
            end

            # Set Oh My Zsh theme
            #
            # @param theme_name [String] The theme name
            sig { params(theme_name: String).void }
            def theme(theme_name)
                @config[:theme] = theme_name
            end

            # Set Oh My Zsh plugins
            #
            # @param plugin_list [Array<String>] List of plugin names
            sig { params(plugin_list: T::Array[String]).void }
            def plugins(plugin_list)
                @config[:plugins] = plugin_list
            end

            # Set extra configuration
            #
            # @param config_text [String] Additional configuration text
            sig { params(config_text: String).void }
            def extra_config(config_text)
                @config[:extra_config] = config_text
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
