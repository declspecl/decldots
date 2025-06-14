#!/usr/bin/env ruby
# typed: false

# Example Rbdots configuration demonstrating MVP functionality
# Run this with: ruby examples/example_config.rb

require_relative "../lib/rbdots"

# Enable dry run mode for safe testing
Rbdots.enable_dry_run

# Create the configuration
config = Rbdots.configure do |config|
    # User information
    config.user do
        name "dec"
        email "gavind2559@gmail.com"
        home_directory "/Users/dec"
    end

    # Package management with Homebrew
    config.packages.homebrew do
        # Add taps first
        tap "homebrew/cask"

        # Install command-line tools
        install "git", "curl", "wget", "jq"
        install "zsh-autosuggestions", "zsh-syntax-highlighting"

        # Install GUI applications via casks
        cask "visual-studio-code", "firefox"
    end

    # Configure zsh shell
    config.programs.zsh do
        enable_completion true
        enable_autosuggestion true
        enable_syntax_highlighting true

        # Set up aliases (replicating your Nix config)
        aliases do
            ls "eza"
            cls "clear"
            hmbs "rbdots apply" # equivalent to your nix hmbs command
        end

        # Oh My Zsh configuration
        oh_my_zsh do
            enable true
            theme "robbyrussell"
            plugins %w[git python man]
        end

        # Custom shell initialization
        shell_init <<~SHELL
                setopt ignore_eof
            #{"    "}
                function fzkill() {
                ps aux | fzf --height 40% --layout=reverse --prompt="Select process to kill: " | awk '{print $2}' | xargs -r sudo kill
            }

            PROMPT=' %{$fg[magenta]%}%0*%{$reset_color%} %{$fg[cyan]%}%0~%{$reset_color%} $(git_prompt_info)$ '
        SHELL

        # Environment variables
        environment_variables({
                                  "RUST_BACKTRACE" => "1"
                              })
    end

    # Configure Git
    config.programs.git do
        user_name "dec"
        user_email "gavind2559@gmail.com"
        default_branch "main"
        pull_rebase true

        # Credential configuration (mimicking your Nix setup)
        set_option :credential_helper, "manager"
        set_option :credential_store, "cache"
        set_option :github_username, "declspecl"
    end

    # Configure dotfiles linking (mimicking your manualDots)
    config.dotfiles do
        source_directory "~/.rbdots/dotfiles"

        # Mutable dotfiles (can be edited directly)
        link "emacs", mutable: true
        link "nvim", mutable: true

        # Immutable dotfiles (copied, not linked)
        link "hypr", mutable: false
        link "kitty", mutable: false
        link "mako", mutable: false
        link "wofi", mutable: false
        link "waybar", mutable: false
        link "wlogout", mutable: false
    end
end

puts "=== Rbdots Example Configuration ==="
puts
puts "This configuration will:"
puts "1. Install packages via Homebrew (git, curl, wget, jq, VS Code, Firefox)"
puts "2. Generate a comprehensive .zshrc with Oh My Zsh, aliases, and custom prompt"
puts "3. Create a .gitconfig with your user info and preferences"
puts "4. Link dotfiles from ~/.rbdots/dotfiles/ to ~/.config/"
puts
puts "To apply this configuration:"
puts "  1. Ensure Homebrew is installed"
puts "  2. Create ~/.rbdots/dotfiles/ directory with your config files"
puts "  3. Run: Rbdots.apply(config)"
puts
puts "To see what changes would be made without applying:"
puts "  Run: pp Rbdots.diff(config)"
puts

# Apply the configuration in dry run mode (safe - creates files in temp directory)
puts "=== Applying Configuration in Dry Run Mode ==="
Rbdots.apply(config)

puts "\n=== Configuration Diff ==="
require "pp"
pp Rbdots.diff(config)
