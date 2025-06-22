# typed: strict
# frozen_string_literal: true

require_relative "base"

module Decldots
    module DSL
        module PackageManagerConfigs
            # Configuration for Homebrew package manager
            class HomebrewConfiguration < BasePackageManagerConfiguration
                extend T::Sig

                sig { returns(T::Array[String]) }
                attr_reader :taps

                sig { returns(T::Array[String]) }
                attr_reader :casks

                sig { void }
                def initialize
                    super
                    @taps = T.let([], T::Array[String])
                    @casks = T.let([], T::Array[String])
                end

                sig { params(taps: T.untyped).void }
                def tap(*taps)
                    @taps.concat(Array(taps).flatten)
                end

                sig { params(casks: T.untyped).void }
                def cask(*casks)
                    @casks.concat(Array(casks).flatten)
                end

                sig { override.returns(T::Boolean) }
                def validate!
                    # Use base class validation but extend it for casks
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
end
