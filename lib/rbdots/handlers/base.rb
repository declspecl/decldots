# typed: strict
# frozen_string_literal: true

module Rbdots
    module Handlers
        # Base class for all program configuration handlers
        class Base
            extend T::Sig
            extend T::Helpers
            abstract!

            # Configure the program with the given options
            sig { abstract.params(options: T::Hash[Symbol, T.untyped]).void }
            def configure(options); end

            # Validate configuration options
            sig { params(_options: T::Hash[Symbol, T.untyped]).returns(T::Boolean) }
            def validate_options(_options)
                # Default implementation - can be overridden by subclasses
                true
            end

            # Show what changes would be made without applying them
            sig { params(_options: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
            def diff_configuration(_options)
                # Default implementation - should be overridden by subclasses
                { action: :configure, 
                  details: "Would configure #{T.must(T.must(self.class.name).split("::").last).downcase}" }
            end

            protected

            # Get the user's home directory
            sig { returns(String) }
            def home_directory
                File.expand_path("~")
            end

            # Write content to a file, creating directories as needed
            sig { params(file_path: String, content: String, backup: T::Boolean).void }
            def write_file(file_path, content, backup: true)
                original_path = File.expand_path(file_path)

                # Transform path for dry run mode
                actual_path = Rbdots.dry_run_path(original_path)

                # Create directory if it doesn't exist
                FileUtils.mkdir_p(File.dirname(actual_path))

                # Backup existing file if requested and not in dry run mode
                backup_file(actual_path) if backup && !Rbdots.dry_run? && File.exist?(actual_path)

                File.write(actual_path, content)

                if Rbdots.dry_run?
                    puts "Would create configuration file: #{original_path} (dry run: #{actual_path})"
                else
                    puts "Created configuration file: #{original_path}"
                end
            end

            # Create a backup of an existing file
            sig { params(file_path: String).void }
            def backup_file(file_path)
                timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
                backup_path = "#{file_path}.backup_#{timestamp}"
                FileUtils.cp(file_path, backup_path)
                puts "Backed up existing file to: #{backup_path}"
            end

            # Read a template file and substitute variables
            sig { params(template_path: String, variables: T::Hash[T.any(String, Symbol), T.untyped]).returns(String) }
            def process_template(template_path, variables = {})
                unless File.exist?(template_path)
                    raise Rbdots::ConfigurationError, 
                          "Template file not found: #{template_path}"
                end

                template_content = File.read(template_path)

                variables.each do |key, value|
                    template_content.gsub!("{{#{key}}}", value.to_s)
                end

                template_content
            end

            # Check if a file exists and has the expected content
            sig { params(file_path: String, expected_content: String).returns(T::Boolean) }
            def file_matches_content?(file_path, expected_content)
                return false unless File.exist?(file_path)

                actual_content = File.read(file_path)
                actual_content.strip == expected_content.strip
            end

            # Get the configuration directory (typically ~/.config)
            sig { returns(String) }
            def config_directory
                File.join(home_directory, ".config")
            end

            # Ensure a directory exists, creating it if necessary
            sig { params(directory_path: String).void }
            def ensure_directory_exists(directory_path)
                FileUtils.mkdir_p(directory_path) unless Dir.exist?(directory_path)
            end
        end
    end
end
