# typed: strict
# frozen_string_literal: true

require_relative "package_manager_configuration/homebrew"

module Decldots
    module DSL
        # Package management DSL interface
        class PackageManagers
            extend T::Sig

            sig { returns(T::Hash[Symbol, PackageManagerConfigs::BasePackageManagerConfiguration]) }
            attr_reader :package_managers

            sig { void }
            def initialize
                @package_managers = T.let({}, T::Hash[Symbol, PackageManagerConfigs::BasePackageManagerConfiguration])
            end

            sig { params(block: T.proc.bind(PackageManagerConfigs::HomebrewConfiguration).void).void }
            def homebrew(&block)
                config = PackageManagerConfigs::HomebrewConfiguration.new
                config.instance_eval(&block)
                @package_managers[:homebrew] = config
                Decldots.register_package_manager(:homebrew, Decldots::PackageManagers::Homebrew)
            end
        end
    end
end
