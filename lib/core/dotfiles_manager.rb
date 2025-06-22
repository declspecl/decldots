# typed: strict
# frozen_string_literal: true

require "fileutils"

module Decldots
    # Manages dotfile linking and copying operations.
    class DotfilesManager
        extend T::Sig

        sig { returns(String) }
        attr_reader :source_directory

        sig { params(source_directory: String).void }
        def initialize(source_directory)
            @source_directory = source_directory
        end

        sig do
            params(
                name: String,
                target: String,
                mutable: T::Boolean,
                source_directory: T.nilable(String)
            ).returns(T::Hash[Symbol, T.untyped])
        end
        def link_config(name, target, mutable, source_directory: nil)
            proper_source_directory = source_directory || @source_directory
            source_path = File.join(proper_source_directory, name)

            validate_link_operation(source_path, target)

            if mutable
                create_mutable_link(
                    source_path,
                    target
                )
            else
                create_immutable_copy(
                    source_path,
                    target
                )
            end

            {
                name: name,
                source: source_path,
                target: target,
                type: mutable ? "mutable" : "immutable",
                created_at: Time.now.iso8601
            }
        end

        sig do
            params(
                name: String,
                mutable: T::Boolean,
                source_directory: T.nilable(String),
                target: T.nilable(String)
            ).returns(T::Hash[Symbol, T.untyped])
        end
        def diff_link(name, mutable: false, source_directory: nil, target: nil)
            proper_source_directory = source_directory || @source_directory
            source_path = File.join(proper_source_directory, name)
            target_path = target || File.expand_path("~/.config/#{name}")

            if File.exist?(target_path) || File.symlink?(target_path)
                if mutable && File.symlink?(target_path) && File.readlink(target_path) == source_path
                    { action: :no_change, reason: "Symlink already exists and points to correct location" }
                elsif !mutable && File.exist?(target_path) && !File.symlink?(target_path)
                    if files_identical?(source_path, target_path)
                        { action: :no_change, reason: "File already exists with correct content" }
                    else
                        { action: :update, reason: "File exists but content differs" }
                    end
                else
                    { action: :replace, reason: "Target exists but type (symlink vs file) differs" }
                end
            else
                { action: :create, reason: "Target does not exist" }
            end
        end

        sig { params(name: String, target: T.nilable(String), source_directory: T.nilable(String)).void }
        def unlink_config(name, target: nil, source_directory: nil)
            proper_source_directory = source_directory || @source_directory
            target_path = target || File.expand_path("~/.config/#{name}")

            if File.exist?(target_path) || File.symlink?(target_path)
                backup_existing_target(target_path)

                if File.symlink?(target_path)
                    FileUtils.rm(target_path)
                    puts "Removed symlink: #{target_path}"
                else
                    FileUtils.rm_rf(target_path)
                    puts "Removed file/directory: #{target_path}"
                end
            else
                puts "Target does not exist: #{target_path}"
            end
        end

        sig do
            params(
                template_path: String,
                target_path: String,
                variables: T::Hash[T.any(String, Symbol), T.untyped]
            ).void
        end
        def copy_template(template_path, target_path, variables = {})
            raise ConfigurationError, "Template file not found: #{template_path}" unless File.exist?(template_path)

            template_content = File.read(template_path)

            variables.each do |key, value|
                template_content.gsub!("{{#{key}}}", value.to_s)
            end

            target_dir = File.dirname(target_path)
            FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

            backup_existing_target(target_path) if File.exist?(target_path)

            File.write(target_path, template_content)
            puts "Created file from template: #{target_path}"
        end

        sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
        def list_current_links
            config_dir = File.expand_path("~/.config")
            return [] unless Dir.exist?(config_dir)

            links = []

            Dir.entries(config_dir).each do |entry|
                next if entry.start_with?(".")

                entry_path = File.join(config_dir, entry)

                if File.symlink?(entry_path)
                    links << {
                        name: entry,
                        target: entry_path,
                        source: File.readlink(entry_path),
                        type: "mutable",
                        is_symlink: true
                    }
                elsif File.exist?(entry_path)
                    links << {
                        name: entry,
                        target: entry_path,
                        type: "immutable",
                        is_symlink: false
                    }
                end
            end

            links
        end

        private

        sig do
            params(
                source_path: String,
                target_path: String
            ).void
        end
        def create_mutable_link(source_path, target_path)
            target_dir = File.dirname(target_path)
            FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

            backup_existing_target(target_path) if (File.exist?(target_path) || File.symlink?(target_path))

            FileUtils.ln_sf(source_path, target_path)

            puts "Created mutable symlink: #{target_path} -> #{source_path}"
        end

        sig do
            params(
                source_path: String,
                target_path: String
            ).void
        end
        def create_immutable_copy(source_path, target_path)
            target_dir = File.dirname(target_path)
            FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

            backup_existing_target(target_path) if (File.exist?(target_path) || File.symlink?(target_path))

            if File.directory?(source_path)
                FileUtils.cp_r(source_path, target_path)
                operation = "directory"
            else
                FileUtils.cp(source_path, target_path)
                operation = "file"
            end

            puts "Copied #{operation} (immutable): #{source_path} -> #{target_path}"
        end

        sig { params(source_path: String, target_path: String).void }
        def validate_link_operation(source_path, target_path)
            unless File.exist?(source_path) || File.directory?(source_path)
                raise ConfigurationError, "Source path does not exist: #{source_path}"
            end

            unless target_path.start_with?(File.expand_path("~"))
                raise ConfigurationError, "Target path must be within user home directory: #{target_path}"
            end

            return unless File.symlink?(target_path)

            link_target = File.readlink(target_path)
            return unless link_target == source_path

            puts "Warning: Link already exists and points to the same source"
        end

        sig { params(target_path: String).void }
        def backup_existing_target(target_path)
            return unless File.exist?(target_path) || File.symlink?(target_path)

            timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
            backup_path = "#{target_path}.backup_#{timestamp}"

            if File.symlink?(target_path)
                FileUtils.rm(target_path)
                puts "Removed existing symlink: #{target_path}"
            else
                FileUtils.mv(target_path, backup_path)
                puts "Backed up existing target to: #{backup_path}"
            end
        end

        sig { params(file1: String, file2: String).returns(T::Boolean) }
        def files_identical?(file1, file2)
            return false unless File.exist?(file1) && File.exist?(file2)
            return false if File.directory?(file1) || File.directory?(file2)

            File.read(file1) == File.read(file2)
        end
    end
end
