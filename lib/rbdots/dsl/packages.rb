# typed: strict
# frozen_string_literal: true

module Rbdots
    module DSL
        # Package management DSL interface
        class Packages
            extend T::Sig

            sig { params(packages_hash: T::Hash[Symbol, T.untyped]).void }
            def initialize(packages_hash)
                @packages = packages_hash
            end

            sig { returns(T::Hash[Symbol, T.untyped]) }
            attr_reader :packages

            sig { params(block: T.nilable(T.proc.void)).void.checked(:never) }
            def homebrew(&block)
                config = PackageManagerConfiguration.new
                config.instance_eval(&block) if block_given?
                @packages[:homebrew] = config
            end

            sig do
                params(_block: T.nilable(T.proc.params(config: PackageManagerConfiguration).void)).void.checked(:never)
            end
            def apt(&_block)
                config = PackageManagerConfiguration.new
                yield(config) if block_given?
                @packages[:apt] = config
            end

            sig do
                params(_block: T.nilable(T.proc.params(config: PackageManagerConfiguration).void)).void.checked(:never)
            end
            def dnf(&_block)
                config = PackageManagerConfiguration.new
                yield(config) if block_given?
                @packages[:dnf] = config
            end

            sig do
                params(_block: T.nilable(T.proc.params(config: PackageManagerConfiguration).void)).void.checked(:never)
            end
            def pacman(&_block)
                config = PackageManagerConfiguration.new
                yield(config) if block_given?
                @packages[:pacman] = config
            end

            sig do
                params(_block: T.nilable(T.proc.params(config: PackageManagerConfiguration).void)).void.checked(:never)
            end
            def yay(&_block)
                config = PackageManagerConfiguration.new
                yield(config) if block_given?
                @packages[:yay] = config
            end
        end

        # Configuration for a specific package manager
        class PackageManagerConfiguration
            extend T::Sig

            sig { returns(T::Array[String]) }
            attr_reader :packages_to_install

            sig { returns(T::Array[String]) }
            attr_reader :packages_to_uninstall

            sig { returns(T::Array[String]) }
            attr_reader :taps

            sig { returns(T::Array[String]) }
            attr_reader :casks

            sig { void }
            def initialize
                @packages_to_install = T.let([], T::Array[String])
                @packages_to_uninstall = T.let([], T::Array[String])
                @taps = T.let([], T::Array[String])
                @casks = T.let([], T::Array[String])
            end

            sig { params(packages: T.untyped).void }
            def install(*packages)
                @packages_to_install.concat(Array(packages).flatten)
            end

            sig { params(packages: T.untyped).void }
            def uninstall(*packages)
                @packages_to_uninstall.concat(Array(packages).flatten)
            end

            sig { params(taps: T.untyped).void }
            def tap(*taps)
                @taps.concat(Array(taps).flatten)
            end

            sig { params(casks: T.untyped).void }
            def cask(*casks)
                @casks.concat(Array(casks).flatten)
            end

            sig { returns(T::Boolean) }
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
            sig { params(packages: T::Array[String]).void }
            def validate_package_names(packages)
                packages.each do |package|
                    if package.strip.empty?
                        raise ValidationError, "Package names must be non-empty strings, got: #{package.inspect}"
                    end
                end
            end

            # Validate tap names are properly formatted
            #
            # @param taps [Array<String>] Tap names to validate
            # @raise [ValidationError] If any tap name is invalid
            sig { params(taps: T::Array[String]).void }
            def validate_tap_names(taps)
                taps.each do |tap|
                    if tap.strip.empty? || !tap.include?("/")
                        raise ValidationError, "Tap names must be in format 'user/repo', got: #{tap.inspect}"
                    end
                end
            end
        end
    end
end
