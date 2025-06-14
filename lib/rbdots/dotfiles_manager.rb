# typed: strict
# frozen_string_literal: true

require "fileutils"

module Rbdots
    # Manages dotfile linking and copying operations
    class DotfilesManager
        extend T::Sig

        # Link or copy a configuration file/directory
        #
        # @param name [String] The name of the configuration
        # @param mutable [Boolean] Whether to create a mutable symlink or immutable copy
        # @param source_directory [String] The source directory containing dotfiles
        # @param target [String, nil] Custom target path (optional)
        sig do
            params(
                name: String,
                mutable: T::Boolean,
                source_directory: T.nilable(String),
                target: T.nilable(String)
            ).returns(T::Hash[Symbol, T.untyped])
        end
        def link_config(name, mutable: false, source_directory: nil, target: nil)
            source_directory ||= File.expand_path("~/.rbdots/dotfiles")
            source_path = File.join(source_directory, name)
            target_path = target || File.expand_path("~/.config/#{name}")

            # Transform paths for dry run mode
            actual_source_path = Rbdots.dry_run_path(source_path)
            actual_target_path = Rbdots.dry_run_path(target_path)

            # In dry run mode, create dummy source files if they don't exist
            create_dummy_source_file(actual_source_path, name) if Rbdots.dry_run? && !File.exist?(actual_source_path)

            validate_link_operation(actual_source_path, actual_target_path)

            if mutable
                create_mutable_link(actual_source_path, actual_target_path, original_source: source_path,
                                                                            original_target: target_path)
            else
                create_immutable_copy(actual_source_path, actual_target_path, original_source: source_path,
                                                                              original_target: target_path)
            end

            {
                name: name,
                source: source_path,
                target: target_path,
                type: mutable ? "mutable" : "immutable",
                created_at: Time.now.iso8601
            }
        end

        # Show what changes would be made without applying them
        #
        # @param name [String] The name of the configuration
        # @param mutable [Boolean] Whether to create a mutable symlink or immutable copy
        # @param source_directory [String] The source directory containing dotfiles
        # @param target [String, nil] Custom target path (optional)
        # @return [Hash] Hash describing the changes
        sig do
            params(
                name: String,
                mutable: T::Boolean,
                source_directory: T.nilable(String),
                target: T.nilable(String)
            ).returns(T::Hash[Symbol, T.untyped])
        end
        def diff_link(name, mutable: false, source_directory: nil, target: nil)
            source_directory ||= File.expand_path("~/.rbdots/dotfiles")
            source_path = File.join(source_directory, name)
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

        # Unlink a configuration
        #
        # @param name [String] The name of the configuration
        # @param target [String, nil] Custom target path (optional)
        sig { params(name: String, target: T.nilable(String)).void }
        def unlink_config(name, target: nil)
            target_path = target || File.expand_path("~/.config/#{name}")

            if File.exist?(target_path) || File.symlink?(target_path)
                # Create backup before removing
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

        # Copy a template file with variable substitution
        #
        # @param template_path [String] Path to the template file
        # @param target_path [String] Target file path
        # @param variables [Hash] Variables to substitute in template
        sig do
            params(
                template_path: String,
                target_path: String,
                variables: T::Hash[T.any(String, Symbol), T.untyped]
            ).void
        end
        def copy_template(template_path, target_path, variables = {})
            raise ConfigurationError, "Template file not found: #{template_path}" unless File.exist?(template_path)

            # Read template content
            template_content = File.read(template_path)

            # Substitute variables
            variables.each do |key, value|
                template_content.gsub!("{{#{key}}}", value.to_s)
            end

            # Ensure target directory exists
            target_dir = File.dirname(target_path)
            FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

            # Backup existing file if it exists
            backup_existing_target(target_path) if File.exist?(target_path)

            # Write processed template
            File.write(target_path, template_content)
            puts "Created file from template: #{target_path}"
        end

        # List all current dotfile links
        #
        # @return [Array<Hash>] List of current dotfile configurations
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

        # Create a mutable symlink
        #
        # @param source_path [String] Source path
        # @param target_path [String] Target path
        # @param original_source [String] Original source path (for display)
        # @param original_target [String] Original target path (for display)
        sig do
            params(
                source_path: String,
                target_path: String,
                original_source: T.nilable(String),
                original_target: T.nilable(String)
            ).void
        end
        def create_mutable_link(source_path, target_path, original_source: nil, original_target: nil)
            # Ensure target directory exists
            target_dir = File.dirname(target_path)
            FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

            # Backup existing target (skip in dry run mode)
            if !Rbdots.dry_run? && (File.exist?(target_path) || File.symlink?(target_path))
                backup_existing_target(target_path)
            end

            # Create symlink
            FileUtils.ln_sf(source_path, target_path)

            if Rbdots.dry_run?
                puts "Would create mutable symlink: #{original_target || target_path} -> #{original_source || source_path} (dry run: #{target_path} -> #{source_path})"
            else
                puts "Created mutable symlink: #{target_path} -> #{source_path}"
            end
        end

        # Create an immutable copy
        #
        # @param source_path [String] Source path
        # @param target_path [String] Target path
        # @param original_source [String] Original source path (for display)
        # @param original_target [String] Original target path (for display)
        sig do
            params(
                source_path: String,
                target_path: String,
                original_source: T.nilable(String),
                original_target: T.nilable(String)
            ).void
        end
        def create_immutable_copy(source_path, target_path, original_source: nil, original_target: nil)
            # Ensure target directory exists
            target_dir = File.dirname(target_path)
            FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

            # Backup existing target (skip in dry run mode)
            if !Rbdots.dry_run? && (File.exist?(target_path) || File.symlink?(target_path))
                backup_existing_target(target_path)
            end

            # Copy file or directory
            if File.directory?(source_path)
                FileUtils.cp_r(source_path, target_path)
                operation = "directory"
            else
                FileUtils.cp(source_path, target_path)
                operation = "file"
            end

            if Rbdots.dry_run?
                puts "Would copy #{operation} (immutable): #{original_source || source_path} -> #{original_target || target_path} (dry run: #{source_path} -> #{target_path})"
            else
                puts "Copied #{operation} (immutable): #{source_path} -> #{target_path}"
            end
        end

        # Validate a link operation before performing it
        #
        # @param source_path [String] Source path
        # @param target_path [String] Target path
        # @raise [ConfigurationError] If validation fails
        sig { params(source_path: String, target_path: String).void }
        def validate_link_operation(source_path, target_path)
            unless File.exist?(source_path) || File.directory?(source_path)
                raise ConfigurationError, "Source path does not exist: #{source_path}"
            end

            # Check if target path is within a reasonable location
            unless target_path.start_with?(File.expand_path("~"))
                raise ConfigurationError, "Target path must be within user home directory: #{target_path}"
            end

            # Check for circular links (basic check)
            return unless File.symlink?(target_path)

            link_target = File.readlink(target_path)
            return unless link_target == source_path

            puts "Warning: Link already exists and points to the same source"
        end

        # Backup an existing target file or directory
        #
        # @param target_path [String] Path to backup
        sig { params(target_path: String).void }
        def backup_existing_target(target_path)
            return unless File.exist?(target_path) || File.symlink?(target_path)

            timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
            backup_path = "#{target_path}.backup_#{timestamp}"

            if File.symlink?(target_path)
                # For symlinks, just remove them (they can be recreated)
                FileUtils.rm(target_path)
                puts "Removed existing symlink: #{target_path}"
            else
                # For files/directories, create a backup
                FileUtils.mv(target_path, backup_path)
                puts "Backed up existing target to: #{backup_path}"
            end
        end

        # Check if two files are identical
        #
        # @param file1 [String] First file path
        # @param file2 [String] Second file path
        # @return [Boolean] True if files are identical
        sig { params(file1: String, file2: String).returns(T::Boolean) }
        def files_identical?(file1, file2)
            return false unless File.exist?(file1) && File.exist?(file2)
            return false if File.directory?(file1) || File.directory?(file2)

            File.read(file1) == File.read(file2)
        end

        # Create a dummy source file for dry run mode
        #
        # @param source_path [String] Path where to create the dummy file
        # @param name [String] Name of the configuration (for content)
        sig { params(source_path: String, name: String).void }
        def create_dummy_source_file(source_path, name)
            FileUtils.mkdir_p(File.dirname(source_path))

            dummy_content = <<~CONTENT
                # Dummy #{name} configuration file created for dry run mode
                # This represents the source file that would be linked or copied
                # Replace this with your actual #{name} configuration

                # Example configuration content for #{name}
            CONTENT

            File.write(source_path, dummy_content)
            puts "Created dummy source file for dry run: #{source_path}"
        end
    end
end
