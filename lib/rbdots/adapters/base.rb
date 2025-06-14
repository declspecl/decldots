# typed: strict
# frozen_string_literal: true

module Rbdots
    module Adapters
        # Custom error for command execution failures
        class CommandError < Rbdots::Error; end

        # Error raised when a command execution fails
        class ConfigurationError < Rbdots::Error; end

        # Base class for all package manager adapters
        class Base
            extend T::Sig
            extend T::Helpers
            abstract!

            # Install packages
            sig { abstract.params(packages: T::Array[String]).void }
            def install(packages); end

            # Uninstall packages
            sig { abstract.params(packages: T::Array[String]).void }
            def uninstall(packages); end

            # Update packages
            sig { abstract.params(packages: T.nilable(T::Array[String])).void }
            def update(packages = nil); end

            # Check if a package is installed
            sig { abstract.params(package: String).returns(T::Boolean) }
            def installed?(package); end

            # Get list of installed packages
            sig { abstract.returns(T::Array[String]) }
            def list_installed; end

            protected

            # Execute a shell command and return the result
            sig { params(command: String, capture_output: T::Boolean).returns(T.any(String, T::Boolean)) }
            def execute_command(command, capture_output: false)
                if Rbdots.dry_run?
                    puts "Dry run: Would execute: #{command}"
                    return capture_output ? "" : true
                end

                if capture_output
                    result = `#{command} 2>&1`
                    raise CommandError, "Command failed: #{command}" unless $?.success?

                    result
                else
                    success = system(command)
                    raise CommandError, "Command failed: #{command}" unless success

                    true
                end
            end

            # Check if a command exists in the system PATH
            sig { params(command: String).returns(T::Boolean) }
            def command_exists?(command)
                !!system("which #{command} > /dev/null 2>&1")
            end

            # Ensure the package manager is available
            sig { void }
            def ensure_package_manager_available!
                manager_command = T.must(T.must(self.class.name).split("::").last).downcase
                return if command_exists?(manager_command)

                raise ConfigurationError, "#{manager_command} is not installed or not in PATH"
            end
        end
    end
end
