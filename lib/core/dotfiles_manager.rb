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
            @source_directory = T.let(File.expand_path(source_directory), String)
        end

        sig { params(link: Link).returns(T::Hash[Symbol, T.untyped]) }
        def link_config(link)
            validate_link_operation!(link.from, link.to)

            if link.action == :link
                create_link(link.from, link.to)
            else
                create_copy(link.from, link.to)
            end

            {
                name: link.name,
                source: link.from,
                target: link.to,
                type: link.action == :link ? "link" : "copy",
                created_at: Time.now.iso8601
            }
        end

        sig { params(link: Link).returns(T::Hash[Symbol, T.untyped]) }
        def diff_link(link)
            if File.exist?(link.to) || File.symlink?(link.to)
                if link.action == :link && File.symlink?(link.to) && File.readlink(link.to) == link.from
                    { action: :no_change, reason: "Symlink already exists and points to correct location" }
                elsif link.action == :copy && File.exist?(link.to) && !File.symlink?(link.to)
                    if files_identical?(link.from, link.to)
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

        sig { params(link: Link).void }
        def unlink_config(link)
            if File.exist?(link.to) || File.symlink?(link.to)
                backup_existing_target(link.to)

                if File.symlink?(link.to)
                    FileUtils.rm(link.to)
                    puts "Removed symlink: #{link.to}"
                else
                    FileUtils.rm_rf(link.to)
                    puts "Removed file/directory: #{link.to}"
                end
            else
                puts "Target does not exist: #{link.to}"
            end
        end

        private

        sig { params(source_path: String, target_path: String).void }
        def create_link(source_path, target_path)
            source_path = File.expand_path(source_path)
            target_path = File.expand_path(target_path)

            target_dir = File.dirname(target_path)
            FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

            backup_existing_target(target_path) if File.exist?(target_path) || File.symlink?(target_path)

            FileUtils.ln_sf(source_path, target_path)

            puts "Created link: #{source_path} -> #{target_path}"
        end

        sig { params(source_path: String, target_path: String).void }
        def create_copy(source_path, target_path)
            source_path = File.expand_path(source_path)
            target_path = File.expand_path(target_path)

            target_dir = File.dirname(target_path)
            FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

            backup_existing_target(target_path) if File.exist?(target_path) || File.symlink?(target_path)

            if File.directory?(source_path)
                FileUtils.cp_r(source_path, target_path)
                operation = "directory"
            else
                FileUtils.cp(source_path, target_path)
                operation = "file"
            end

            puts "Copied #{operation}: #{source_path} -> #{target_path}"
        end

        sig { params(source_path: String, target_path: String).void }
        def validate_link_operation!(source_path, target_path)
            source_path = File.expand_path(source_path)
            target_path = File.expand_path(target_path)

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
            target_path = File.expand_path(target_path)

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
            file1 = File.expand_path(file1)
            file2 = File.expand_path(file2)

            return false unless File.exist?(file1) && File.exist?(file2)
            return false if File.directory?(file1) || File.directory?(file2)

            File.read(file1) == File.read(file2)
        end
    end

    class Link
        extend T::Sig

        sig { returns(String) }
        attr_reader :name

        sig { returns(Symbol) }
        attr_reader :action

        sig { returns(String) }
        attr_reader :to

        sig { returns(String) }
        attr_reader :from

        sig { params(name: String, action: Symbol, to: String, from: T.nilable(String)).void }
        def initialize(name, action, to, from: nil)
            @name = name
            @action = action
            @to = T.let(File.expand_path(to), String)
            @from = T.let(File.expand_path(from || File.join(Decldots.source_directory, name)), String)
        end
    end
end
