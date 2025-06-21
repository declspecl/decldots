# typed: strict
# frozen_string_literal: true

module Decldots
    module DSL
        # Package management DSL interface
        class PackageManagement
            extend T::Sig

            sig { returns(T::Hash[Symbol, PackageManagerConfiguration]) }
            attr_reader :packages

            sig { void }
            def initialize
                @packages = T.let({}, T::Hash[Symbol, PackageManagerConfiguration])
            end

            sig { params(block: T.proc.bind(PackageManagerConfiguration).void).void.checked(:never) }
            def homebrew(&block)
                config = PackageManagerConfiguration.new
                config.instance_eval(&block)
                @packages[:homebrew] = config
            end

            sig do
                params(_block: T.proc.params(config: PackageManagerConfiguration).void).void.checked(:never)
            end
            def apt(&_block)
                config = PackageManagerConfiguration.new
                yield(config)
                @packages[:apt] = config
            end

            sig do
                params(_block: T.proc.params(config: PackageManagerConfiguration).void).void.checked(:never)
            end
            def dnf(&_block)
                config = PackageManagerConfiguration.new
                yield(config)
                @packages[:dnf] = config
            end

            sig do
                params(_block: T.proc.params(config: PackageManagerConfiguration).void).void.checked(:never)
            end
            def pacman(&_block)
                config = PackageManagerConfiguration.new
                yield(config)
                @packages[:pacman] = config
            end

            sig do
                params(_block: T.proc.params(config: PackageManagerConfiguration).void).void.checked(:never)
            end
            def yay(&_block)
                config = PackageManagerConfiguration.new
                yield(config)
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

            sig { params(packages: T::Array[String]).void }
            def validate_package_names(packages)
                packages.each do |package|
                    if package.strip.empty?
                        raise ValidationError, "Package names must be non-empty strings, got: #{package.inspect}"
                    end
                end
            end

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
