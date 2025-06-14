# frozen_string_literal: true

require_relative "base"

module Rbdots
    module Adapters
        # Homebrew package manager adapter
        class Homebrew < Base
            def initialize
                ensure_package_manager_available!
            end

            # Install packages and casks
            #
            # @param packages [Array<String>] Package names to install
            def install(packages)
                return if packages.empty?

                packages.each do |package|
                    if installed?(package)
                        puts "Package #{package} is already installed"
                        next
                    end

                    puts "Installing #{package}..."
                    execute_command("brew install #{package}")
                end
            end

            # Install Homebrew casks (GUI applications)
            #
            # @param casks [Array<String>] Cask names to install
            def install_casks(casks)
                return if casks.empty?

                casks.each do |cask|
                    if cask_installed?(cask)
                        puts "Cask #{cask} is already installed"
                        next
                    end

                    puts "Installing cask #{cask}..."
                    execute_command("brew install --cask #{cask}")
                end
            end

            # Add Homebrew taps (third-party repositories)
            #
            # @param taps [Array<String>] Tap names to add
            def add_taps(taps)
                return if taps.empty?

                taps.each do |tap|
                    if tap_exists?(tap)
                        puts "Tap #{tap} is already added"
                        next
                    end

                    puts "Adding tap #{tap}..."
                    execute_command("brew tap #{tap}")
                end
            end

            # Uninstall packages
            #
            # @param packages [Array<String>] Package names to uninstall
            def uninstall(packages)
                return if packages.empty?

                packages.each do |package|
                    unless installed?(package)
                        puts "Package #{package} is not installed"
                        next
                    end

                    puts "Uninstalling #{package}..."
                    execute_command("brew uninstall #{package}")
                end
            end

            # Update packages
            #
            # @param packages [Array<String>, nil] Specific packages to update, or nil for all
            def update(packages = nil)
                if packages.nil?
                    puts "Updating Homebrew..."
                    execute_command("brew update")
                    execute_command("brew upgrade")
                else
                    packages.each do |package|
                        if installed?(package)
                            puts "Updating #{package}..."
                            execute_command("brew upgrade #{package}")
                        else
                            puts "Package #{package} is not installed, skipping update"
                        end
                    end
                end
            end

            # Check if a package is installed
            #
            # @param package [String] Package name to check
            # @return [Boolean] True if package is installed
            def installed?(package)
                execute_command("brew list #{package}", capture_output: true)
                true
            rescue CommandError
                false
            end

            # Check if a cask is installed
            #
            # @param cask [String] Cask name to check
            # @return [Boolean] True if cask is installed
            def cask_installed?(cask)
                execute_command("brew list --cask #{cask}", capture_output: true)
                true
            rescue CommandError
                false
            end

            # Check if a tap exists
            #
            # @param tap [String] Tap name to check
            # @return [Boolean] True if tap is added
            def tap_exists?(tap)
                taps = execute_command("brew tap", capture_output: true)
                taps.include?(tap)
            rescue CommandError
                false
            end

            # Get list of installed packages
            #
            # @return [Array<String>] List of installed package names
            def list_installed
                result = execute_command("brew list --formula", capture_output: true)
                result.strip.split("\n")
            rescue CommandError
                []
            end

            # Get list of installed casks
            #
            # @return [Array<String>] List of installed cask names
            def list_installed_casks
                result = execute_command("brew list --cask", capture_output: true)
                result.strip.split("\n")
            rescue CommandError
                []
            end

            # Clean up old versions and cached files
            def cleanup
                puts "Cleaning up Homebrew..."
                execute_command("brew cleanup")
            end

            # Show Homebrew system information
            def doctor
                puts "Running Homebrew doctor..."
                execute_command("brew doctor")
            end

            protected

            # Ensure Homebrew is available
            def ensure_package_manager_available!
                return if command_exists?("brew")

                raise ConfigurationError, "Homebrew is not installed. Install it from https://brew.sh"
            end
        end
    end
end
