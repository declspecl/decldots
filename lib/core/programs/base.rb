# typed: strict
# frozen_string_literal: true

module Decldots
    module Programs
        # Base class for all program configuration programs
        class Base
            extend T::Sig
            extend T::Helpers
            abstract!

            sig { abstract.params(options: T::Hash[Symbol, T.untyped]).void }
            def configure(options); end

            sig { abstract.params(_options: T::Hash[Symbol, T.untyped]).void }
            def validate_options!(_options); end

            sig { params(_options: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
            def diff_configuration(_options)
                { action: :configure, 
                  details: "Would configure #{T.must(T.must(self.class.name).split("::").last).downcase}" }
            end

            protected

            sig { returns(String) }
            def home_directory
                File.expand_path("~")
            end

            sig { params(file_path: String, content: String, backup: T::Boolean).void }
            def write_file(file_path, content, backup: true)
                original_path = File.expand_path(file_path)

                FileUtils.mkdir_p(File.dirname(original_path))

                backup_file(original_path) if backup && File.exist?(original_path)

                File.write(original_path, content)
            end

            sig { params(file_path: String).void }
            def backup_file(file_path)
                timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
                backup_path = "#{file_path}.backup_#{timestamp}"
                FileUtils.cp(file_path, backup_path)
                puts "Backed up existing file to: #{backup_path}"
            end

            sig { params(template_path: String, variables: T::Hash[T.any(String, Symbol), T.untyped]).returns(String) }
            def process_template(template_path, variables = {})
                unless File.exist?(template_path)
                    raise Decldots::ConfigurationError, 
                          "Template file not found: #{template_path}"
                end

                template_content = File.read(template_path)

                variables.each do |key, value|
                    template_content.gsub!("{{#{key}}}", value.to_s)
                end

                template_content
            end

            sig { params(file_path: String, expected_content: String).returns(T::Boolean) }
            def file_matches_content?(file_path, expected_content)
                return false unless File.exist?(file_path)

                actual_content = File.read(file_path)
                actual_content.strip == expected_content.strip
            end

            sig { returns(String) }
            def config_directory
                File.join(home_directory, ".config")
            end

            sig { params(directory_path: String).void }
            def ensure_directory_exists(directory_path)
                FileUtils.mkdir_p(directory_path) unless Dir.exist?(directory_path)
            end
        end
    end
end
