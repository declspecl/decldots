#!/usr/bin/env ruby
# typed: strict
# frozen_string_literal: true

require_relative "../lib/decldots"

Decldots.initialize("~/.dotfiles")
Decldots.enable_dry_run

config = Decldots.configure do |config|
    config.package_managers.homebrew do
        tap "homebrew/cask-fonts", "homebrew/cask-versions"

        install "git", "curl", "wget", "jq", "vim", "tmux", "ripgrep", "fd", "bat"
        install "zsh-autosuggestions", "zsh-syntax-highlighting"

        cask "font-fira-code", "visual-studio-code", "firefox", "iterm2"
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

            function fzkill() {
                ps aux | fzf --height 40% --layout=reverse --prompt="Select process to kill: " | awk '{print $2}' | xargs -r sudo kill
            }

            PROMPT=' %{$fg[magenta]%}%0*%{$reset_color%} %{$fg[cyan]%}%0~%{$reset_color%} $(git_prompt_info)$ '
        SHELL

        environment_variable :RUST_BACKTRACE, "1"
    end

    config.programs.git do
        user_name "Your Name"
        user_email "yourname@gmail.com"
        default_branch "main"
        pull_rebase true

        set_option :github_username, "yourusername"
    end

    config.programs.bash do
        enable_completion
        history_size 5000
      
        set_alias :ll, "ls -la"
        set_alias :la, "ls -A"
        set_alias :grep, "grep --color=auto"
    end

    config.programs.vim do
        enable_syntax_highlighting
        enable_line_numbers
        tab_width 4
        expand_tabs
        color_scheme "desert"
        enable_mouse

        set_key_mapping :"<leader>t", ":NERDTreeToggle<CR>"
        set_key_mapping :"<C-n>", ":bnext<CR>"
        set_key_mapping :"<C-p>", ":bprevious<CR>"
    end

    config.programs.ssh do
        enable_compression
        connect_timeout 30
        server_alive_interval 60
        server_alive_count_max 3
        enable_agent_forwarding
      
        hosts({
                  "production" => {
                      "hostname" => "prod.example.com",
                      "user" => "deploy",
                      "port" => "22",
                      "identityFile" => "~/.ssh/production_key"
                  },
                  "staging" => {
                      "hostname" => "staging.example.com",
                      "user" => "deploy",
                      "port" => "2222"
                  }
              }
             )
    end

    config.programs.tmux do
        prefix_key "C-a"
        enable_mouse
        enable_vi_mode
        history_limit 50_000
        base_index 1
        enable_clipboard
        enable_status_bar
        status_position "bottom"
      
        key_bindings({
                         "r" => "source-file ~/.tmux.conf \\; display-message \"Config reloaded!\"",
                         "|" => "split-window -h",
                         "-" => "split-window -v"
                     }
                    )
      
        plugins [
            "tmux-plugins/tpm",
            "tmux-plugins/tmux-sensible",
            "tmux-plugins/tmux-resurrect"
        ]
    end

    config.dotfiles do
        link "emacs", "~/.emacs.d"
        link "nvim", "~/.config/nvim"
    end
end

diff = Decldots.diff(config)
puts "=== Configuration Diff ==="
diff.each do |category, changes|
    puts "\n#{category.to_s.capitalize}:"
    changes.each do |change|
        puts "  #{change}"
    end
end

puts "Applying configuration..."
Decldots.apply!(config)
puts "Configuration applied successfully!"
