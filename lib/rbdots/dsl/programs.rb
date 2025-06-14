# frozen_string_literal: true

module Rbdots
    module DSL
        # Program configuration DSL interface
        class Programs
            def initialize(programs_hash)
                @programs = programs_hash
            end

            # Configure zsh shell
            #
            # @yield [zsh] Zsh configuration block
            def zsh(&block)
                config = ProgramConfiguration.new
                block.call(config) if block_given?
                @programs[:zsh] = config
            end

            # Configure bash shell
            #
            # @yield [bash] Bash configuration block
            def bash(&block)
                config = ProgramConfiguration.new
                block.call(config) if block_given?
                @programs[:bash] = config
            end

            # Configure git
            #
            # @yield [git] Git configuration block
            def git(&block)
                config = ProgramConfiguration.new
                block.call(config) if block_given?
                @programs[:git] = config
            end

            # Configure VSCode
            #
            # @yield [vscode] VSCode configuration block
            def vscode(&block)
                config = ProgramConfiguration.new
                block.call(config) if block_given?
                @programs[:vscode] = config
            end
        end

        # Configuration for a specific program
        class ProgramConfiguration
            attr_reader :options

            def initialize
                @options = {}
            end

            # Enable completion (shell specific)
            #
            # @param enabled [Boolean] Whether to enable completion
            def enable_completion(enabled = true)
                @options[:enable_completion] = enabled
            end

            # Enable autosuggestion (shell specific)
            #
            # @param enabled [Boolean] Whether to enable autosuggestion
            def enable_autosuggestion(enabled = true)
                @options[:enable_autosuggestion] = enabled
            end

            # Enable syntax highlighting (shell specific)
            #
            # @param enabled [Boolean] Whether to enable syntax highlighting
            def enable_syntax_highlighting(enabled = true)
                @options[:enable_syntax_highlighting] = enabled
            end

            # Configure shell aliases
            #
            # @yield [aliases] Aliases configuration block
            def aliases(&block)
                aliases_config = AliasesConfiguration.new
                block.call(aliases_config) if block_given?
                @options[:aliases] = aliases_config.to_hash
            end

            # Set shell initialization script
            #
            # @param script [String] The shell script to run on initialization
            def shell_init(script)
                @options[:shell_init] = script
            end

            # Configure Oh My Zsh (zsh specific)
            #
            # @yield [omz] Oh My Zsh configuration block
            def oh_my_zsh(&block)
                omz_config = OhMyZshConfiguration.new
                block.call(omz_config) if block_given?
                @options[:oh_my_zsh] = omz_config.to_hash
            end

            # Set git user name
            #
            # @param name [String] The git user name
            def user_name(name)
                @options[:user_name] = name
            end

            # Set git user email
            #
            # @param email [String] The git user email
            def user_email(email)
                @options[:user_email] = email
            end

            # Set git default branch
            #
            # @param branch [String] The default branch name
            def default_branch(branch)
                @options[:default_branch] = branch
            end

            # Set git pull behavior
            #
            # @param enabled [Boolean] Whether to rebase on pull
            def pull_rebase(enabled = true)
                @options[:pull_rebase] = enabled
            end

            # Set environment variables
            #
            # @param vars [Hash] Hash of environment variable name/value pairs
            def environment_variables(vars)
                @options[:environment_variables] = vars
            end

            # Set a generic option
            #
            # @param key [Symbol] The option key
            # @param value [Object] The option value
            def set_option(key, value)
                @options[key] = value
            end

            # Validate the program configuration
            #
            # @return [Boolean] True if valid
            # @raise [ValidationError] If configuration is invalid
            def validate!
                # Basic validation - can be extended per program type
                true
            end
        end

        # Helper class for configuring shell aliases
        class AliasesConfiguration
            def initialize
                @aliases = {}
            end

            # Set an alias
            #
            # @param name [String, Symbol] The alias name
            # @param command [String] The command to alias to
            def method_missing(name, command = nil)
                if command
                    @aliases[name.to_s] = command
                else
                    super
                end
            end

            # Check if we respond to a method (for alias setting)
            def respond_to_missing?(_name, _include_private = false)
                true
            end

            # Convert to hash
            #
            # @return [Hash] The aliases as a hash
            def to_hash
                @aliases
            end
        end

        # Helper class for configuring Oh My Zsh
        class OhMyZshConfiguration
            def initialize
                @config = {}
            end

            # Enable Oh My Zsh
            #
            # @param enabled [Boolean] Whether to enable Oh My Zsh
            def enable(enabled = true)
                @config[:enable] = enabled
            end

            # Set Oh My Zsh theme
            #
            # @param theme_name [String] The theme name
            def theme(theme_name)
                @config[:theme] = theme_name
            end

            # Set Oh My Zsh plugins
            #
            # @param plugin_list [Array<String>] List of plugin names
            def plugins(plugin_list)
                @config[:plugins] = plugin_list
            end

            # Set extra configuration
            #
            # @param config_text [String] Additional configuration text
            def extra_config(config_text)
                @config[:extra_config] = config_text
            end

            # Convert to hash
            #
            # @return [Hash] The configuration as a hash
            def to_hash
                @config
            end
        end
    end
end
