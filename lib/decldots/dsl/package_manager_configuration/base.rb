# typed: strict
# frozen_string_literal: true

module Decldots
    module DSL
        module PackageManagerConfigs
            # Abstract base class for package manager configurations
            # Provides common interface and validation patterns for all package managers
            class BasePackageManagerConfiguration
                extend T::Sig
                extend T::Helpers
                abstract!

                sig { returns(T::Array[String]) }
                attr_reader :packages_to_install

                sig { returns(T::Array[String]) }
                attr_reader :packages_to_uninstall

                sig { void }
                def initialize
                    @packages_to_install = T.let([], T::Array[String])
                    @packages_to_uninstall = T.let([], T::Array[String])
                end

                sig { params(packages: T.untyped).void }
                def install(*packages)
                    @packages_to_install.concat(Array(packages).flatten)
                end

                sig { params(packages: T.untyped).void }
                def uninstall(*packages)
                    @packages_to_uninstall.concat(Array(packages).flatten)
                end

                # Abstract method that must be implemented by subclasses
                sig { abstract.returns(T::Boolean) }
                def validate!; end

                protected

                # Common validation helper for package names
                sig { params(packages: T::Array[String]).void }
                def validate_package_names(packages)
                    packages.each do |package|
                        if package.strip.empty?
                            raise ValidationError, "Package names must be non-empty strings, got: #{package.inspect}"
                        end
                    end
                end

                # Template method for basic validation that subclasses can extend
                sig { returns(T::Boolean) }
                def validate_basic_requirements!
                    if @packages_to_install.empty? && @packages_to_uninstall.empty?
                        raise ValidationError, 
                              "Package configuration must specify at least one package to install or uninstall"
                    end

                    validate_package_names(@packages_to_install)
                    validate_package_names(@packages_to_uninstall)

                    true
                end
            end
        end
    end
end
