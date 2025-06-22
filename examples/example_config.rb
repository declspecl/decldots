#!/usr/bin/env ruby
# typed: strict
# frozen_string_literal: true

require_relative "../lib/decldots"

Decldots.enable_dry_run

config = Decldots.configure do |config|
    config.package_managers.homebrew do
        tap "homebrew/cask"

        install "git", "curl", "wget", "jq"
        install "zsh-autosuggestions", "zsh-syntax-highlighting"

        cask "visual-studio-code", "firefox"
    end

    config.programs.zsh do
        enable_completion
        enable_autosuggestion
        enable_syntax_highlighting

        set_alias :ls, "eza"
        set_alias :cls, "clear"
        set_alias :gs, "git status"
        set_alias :ga, "git add"
        set_alias :gaa, "git add --all"
        set_alias :gcm, "git commit -m"
        set_alias :gca, "git commit --amend"
        set_alias :gcaa, "git commit --amend --all"

        oh_my_zsh do
            enable
            theme "robbyrussell"
            plugins %w[git python man zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting]
        end

        shell_init <<~SHELL
                setopt ignore_eof
            #{"    "}
                function fzkill() {
                ps aux | fzf --height 40% --layout=reverse --prompt="Select process to kill: " | awk '{print $2}' | xargs -r sudo kill
            }

            PROMPT=' %{$fg[magenta]%}%0*%{$reset_color%} %{$fg[cyan]%}%0~%{$reset_color%} $(git_prompt_info)$ '
        SHELL

        environment_variable :RUST_BACKTRACE, "1"
    end

    config.programs.git do
        user_name "dec"
        user_email "gavind2559@gmail.com"
        default_branch "main"
        pull_rebase true

        set_option :github_username, "declspecl"
    end

    config.dotfiles do
        source_directory "~/.decldots/dotfiles"

        link "emacs", mutable: true
        link "nvim", mutable: true

        link "hypr", mutable: false
        link "kitty", mutable: false
        link "mako", mutable: false
        link "wofi", mutable: false
        link "waybar", mutable: false
        link "wlogout", mutable: false
    end
end

puts "=== Applying Configuration in Dry Run Mode ==="
Decldots.apply(config)

puts "\n=== Configuration Diff ==="
require "pp"
pp Decldots.diff(config)
