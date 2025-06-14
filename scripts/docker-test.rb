#!/usr/bin/env ruby

require_relative "../lib/rbdots"

# Docker-specific test configuration
Rbdots.configure do |config|
    # Enable dry-run mode for safety
    config.dry_run = true

    puts "🐳 Running Rbdots tests in Docker environment"
    puts "📁 Current working directory: #{Dir.pwd}"
    puts "👤 Current user: #{`whoami`.strip}"
    puts "🏠 Home directory: #{ENV["HOME"]}"
    puts ""

    # Test package management
    puts "📦 Testing package management..."
    config.packages do
        homebrew do
            packages %w[neovim git curl wget]
            casks %w[visual-studio-code]
            taps %w[homebrew/cask-fonts]
        end
    end

    # Test program configuration
    puts "⚙️ Testing program configuration..."
    config.programs do
        shell do
            type :zsh
            oh_my_zsh do
                enable true
                theme "robbyrussell"
                plugins %w[git ruby docker]
            end
            aliases({
                        "ll" => "ls -la",
                        "la" => "ls -A",
                        "l" => "ls -CF",
                        "test-docker" => "echo 'Running in Docker container!'"
                    })
        end

        git do
            user_name "Docker Test User"
            user_email "test@docker.example.com"
            aliases({
                        "st" => "status",
                        "co" => "checkout",
                        "br" => "branch"
                    })
        end
    end

    # Test dotfiles management
    puts "📄 Testing dotfiles management..."
    config.dotfiles do
        source_dir "#{ENV["HOME"]}/.rbdots/dotfiles"

        link "nvim", to: "#{ENV["HOME"]}/.config/nvim", mutable: true
        link "emacs", to: "#{ENV["HOME"]}/.config/emacs", mutable: false
        copy "hypr", to: "#{ENV["HOME"]}/.config/hypr/hyprland.conf"
        copy "kitty", to: "#{ENV["HOME"]}/.config/kitty/kitty.conf"
    end
end

puts "✅ Docker test configuration completed successfully!"
puts ""
puts "To run the actual configuration:"
puts "  bundle exec rbdots apply"
puts ""
puts "To see what would be changed:"
puts "  bundle exec rbdots diff"
puts ""
puts "To test individual commands:"
puts "  bundle exec rbdots example"
