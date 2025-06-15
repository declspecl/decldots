# typed: strict
# frozen_string_literal: true

require_relative "base"

module Rbdots
    module PackageManagers
        # Homebrew package manager implementation
        class Homebrew < Base
            extend T::Sig

            sig { void }
            def initialize
                super
                ensure_package_manager_available!
            end

            sig { override.params(packages: T::Array[String]).void }
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

            sig { params(casks: T::Array[String]).void }
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

            sig { params(taps: T::Array[String]).void }
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

            sig { override.params(packages: T::Array[String]).void }
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

            sig { override.params(packages: T.nilable(T::Array[String])).void }
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

            sig { override.params(package: String).returns(T::Boolean) }
            def installed?(package)
                return false if Rbdots.dry_run?

                execute_command("brew list #{package}", capture_output: true)
                true
            rescue CommandError
                false
            end

            sig { params(cask: String).returns(T::Boolean) }
            def cask_installed?(cask)
                return false if Rbdots.dry_run?

                execute_command("brew list --cask #{cask}", capture_output: true)
                true
            rescue CommandError
                false
            end

            sig { params(tap: String).returns(T::Boolean) }
            def tap_exists?(tap)
                return false if Rbdots.dry_run?

                taps = T.cast(execute_command("brew tap", capture_output: true), String)
                taps.include?(tap)
            rescue CommandError
                false
            end

            sig { override.returns(T::Array[String]) }
            def list_installed
                result = T.cast(execute_command("brew list --formula", capture_output: true), String)
                result.strip.split("\n")
            rescue CommandError
                []
            end

            sig { returns(T::Array[String]) }
            def list_installed_casks
                result = T.cast(execute_command("brew list --cask", capture_output: true), String)
                result.strip.split("\n")
            rescue CommandError
                []
            end

            sig { returns(T::Array[String]) }
            def list_outdated
                result = T.cast(execute_command("brew outdated", capture_output: true), String)
                result.strip.split("\n")
            rescue CommandError
                []
            end

            sig { params(package: String).returns(T::Hash[String, T.untyped]) }
            def package_info(package)
                result = T.cast(execute_command("brew info #{package} --json", capture_output: true), String)
                require "json"
                JSON.parse(result).first
            rescue CommandError, JSON::ParserError
                {}
            end

            sig { params(query: String).returns(T::Array[String]) }
            def search(query)
                result = T.cast(execute_command("brew search #{query}", capture_output: true), String)
                result.strip.split("\n")
            rescue CommandError
                []
            end

            sig { void }
            def cleanup
                puts "Cleaning up Homebrew..."
                execute_command("brew cleanup")
            end

            sig { void }
            def doctor
                puts "Running Homebrew doctor..."
                execute_command("brew doctor")
            end

            protected

            sig { void }
            def ensure_package_manager_available!
                return if command_exists?("brew")

                raise ConfigurationError, "Homebrew is not installed. Install it from https://brew.sh"
            end
        end
    end
end
