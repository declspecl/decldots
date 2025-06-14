# frozen_string_literal: true

module Rbdots
    module DSL
        # Package management DSL interface
        class Packages
            def initialize(packages_hash)
                @packages = packages_hash
            end

            # Configure Homebrew packages
            #
            # @yield [homebrew] Homebrew configuration block
            def homebrew(&block)
                config = PackageManagerConfiguration.new
                block.call(config) if block_given?
                @packages[:homebrew] = config
            end

            # Configure APT packages (for Debian/Ubuntu systems)
            #
            # @yield [apt] APT configuration block
            def apt(&block)
                config = PackageManagerConfiguration.new
                block.call(config) if block_given?
                @packages[:apt] = config
            end

            # Configure DNF packages (for Fedora systems)
            #
            # @yield [dnf] DNF configuration block
            def dnf(&block)
                config = PackageManagerConfiguration.new
                block.call(config) if block_given?
                @packages[:dnf] = config
            end

            # Configure Pacman packages (for Arch systems)
            #
            # @yield [pacman] Pacman configuration block
            def pacman(&block)
                config = PackageManagerConfiguration.new
                block.call(config) if block_given?
                @packages[:pacman] = config
            end
        end

        # Configuration for a specific package manager
        class PackageManagerConfiguration
            attr_reader :packages_to_install, :packages_to_uninstall, :taps, :casks

            def initialize
                @packages_to_install = []
                @packages_to_uninstall = []
                @taps = []
                @casks = []
            end

            # Install packages
            #
            # @param packages [Array<String>, String] Package names to install
            def install(*packages)
                @packages_to_install.concat(Array(packages).flatten)
            end

            # Uninstall packages
            #
            # @param packages [Array<String>, String] Package names to uninstall
            def uninstall(*packages)
                @packages_to_uninstall.concat(Array(packages).flatten)
            end

            # Add Homebrew taps (Homebrew specific)
            #
            # @param taps [Array<String>, String] Tap names to add
            def tap(*taps)
                @taps.concat(Array(taps).flatten)
            end

            # Install Homebrew casks (Homebrew specific)
            #
            # @param casks [Array<String>, String] Cask names to install
            def cask(*casks)
                @casks.concat(Array(casks).flatten)
            end

            # Validate the package configuration
            #
            # @return [Boolean] True if valid
            # @raise [ValidationError] If configuration is invalid
            def validate!
                if @packages_to_install.empty? && @packages_to_uninstall.empty? && @casks.empty?
                    raise ValidationError, 
                          "Package configuration must specify at least one package to install or uninstall"
                end

                validate_package_names(@packages_to_install)
                validate_package_names(@packages_to_uninstall)
                validate_package_names(@casks)
                validate_tap_names(@taps)

                true
            end

            private

            # Validate package names are non-empty strings
            #
            # @param packages [Array<String>] Package names to validate
            # @raise [ValidationError] If any package name is invalid
            def validate_package_names(packages)
                packages.each do |package|
                    unless package.is_a?(String) && !package.strip.empty?
                        raise ValidationError, "Package names must be non-empty strings, got: #{package.inspect}"
                    end
                end
            end

            # Validate tap names are properly formatted
            #
            # @param taps [Array<String>] Tap names to validate
            # @raise [ValidationError] If any tap name is invalid
            def validate_tap_names(taps)
                taps.each do |tap|
                    unless tap.is_a?(String) && tap.include?("/")
                        raise ValidationError, "Tap names must be in format 'user/repo', got: #{tap.inspect}"
                    end
                end
            end
        end
    end
end
