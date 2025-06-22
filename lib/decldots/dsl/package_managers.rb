# typed: strict
# frozen_string_literal: true

require_relative "package_manager_configuration/homebrew"

module Decldots
    module DSL
        # Package management DSL interface
        class PackageManagers
            extend T::Sig

            sig { returns(T::Hash[Symbol, PackageManagerConfigs::BasePackageManagerConfiguration]) }
            attr_reader :packages

            sig { void }
            def initialize
                @packages = T.let({}, T::Hash[Symbol, PackageManagerConfigs::BasePackageManagerConfiguration])
            end

            sig { params(block: T.proc.bind(PackageManagerConfigs::HomebrewConfiguration).void).void.checked(:never) }
            def homebrew(&block)
                config = PackageManagerConfigs::HomebrewConfiguration.new
                config.instance_eval(&block)
                @packages[:homebrew] = config
            end
        end
    end
end
