# typed: strict
# frozen_string_literal: true

require "English"
module Decldots
    module PackageManagers
        # Error raised when a command execution fails
        class CommandError < Decldots::Error; end

        # Error raised when a package manager configuration is invalid
        class ConfigurationError < Decldots::Error; end

        # Base class for all package managers
        class Base
            extend T::Sig
            extend T::Helpers
            abstract!

            sig { abstract.params(packages: T::Array[String]).void }
            def install(packages); end

            sig { abstract.params(packages: T::Array[String]).void }
            def uninstall(packages); end

            sig { abstract.params(packages: T.nilable(T::Array[String])).void }
            def update(packages = nil); end

            sig { abstract.params(package: String).returns(T::Boolean) }
            def installed?(package); end

            sig { abstract.returns(T::Array[String]) }
            def list_installed; end

            protected

            sig { params(command: String, capture_output: T::Boolean).returns(T.any(String, T::Boolean)) }
            def execute_command(command, capture_output: false)
                if capture_output
                    result = `#{command} 2>&1`
                    raise CommandError, "Command failed: #{command}" unless $CHILD_STATUS.success?

                    result
                else
                    success = system(command)
                    raise CommandError, "Command failed: #{command}" unless success

                    true
                end
            end

            sig { params(command: String).returns(T::Boolean) }
            def command_exists?(command)
                !!system("which #{command} > /dev/null 2>&1")
            end

            sig { void }
            def ensure_package_manager_available!
                manager_command = T.must(T.must(self.class.name).split("::").last).downcase
                return if command_exists?(manager_command)

                raise ConfigurationError, "#{manager_command} is not installed or not in PATH"
            end
        end
    end
end
