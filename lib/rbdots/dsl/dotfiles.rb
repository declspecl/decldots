# frozen_string_literal: true

module Rbdots
    module DSL
        # Dotfiles configuration DSL interface
        class Dotfiles
            attr_reader :links, :source_directory

            def initialize
                @links = []
                @source_directory = File.expand_path("~/.rbdots/dotfiles")
            end

            # Set the source directory for dotfiles
            #
            # @param directory [String] The directory containing dotfile sources
            def source_directory(directory)
                @source_directory = File.expand_path(directory)
            end

            # Link a dotfile configuration
            #
            # @param name [String] The name of the configuration (matches directory/file name)
            # @param mutable [Boolean] Whether the link should be mutable (symlink) or immutable (copy)
            # @param target [String, nil] Custom target path (defaults to ~/.config/{name})
            def link(name, mutable: false, target: nil)
                target_path = target || File.expand_path("~/.config/#{name}")

                @links << {
                    name: name,
                    mutable: mutable,
                    target: target_path,
                    source: File.join(@source_directory, name)
                }
            end

            # Link multiple dotfiles with the same mutability setting
            #
            # @param names [Array<String>] Array of configuration names
            # @param mutable [Boolean] Whether the links should be mutable
            def link_multiple(names, mutable: false)
                names.each { |name| link(name, mutable: mutable) }
            end

            # Link a mutable dotfile (convenience method)
            #
            # @param name [String] The name of the configuration
            # @param target [String, nil] Custom target path
            def link_mutable(name, target: nil)
                link(name, mutable: true, target: target)
            end

            # Link an immutable dotfile (convenience method)
            #
            # @param name [String] The name of the configuration
            # @param target [String, nil] Custom target path
            def link_immutable(name, target: nil)
                link(name, mutable: false, target: target)
            end

            # Copy a file instead of linking
            #
            # @param source [String] Source file path (relative to source_directory)
            # @param target [String] Target file path
            # @param backup [Boolean] Whether to backup existing files
            def copy(source, target, backup: true)
                source_path = File.join(@source_directory, source)
                target_path = File.expand_path(target)

                @links << {
                    name: File.basename(source),
                    mutable: false,
                    target: target_path,
                    source: source_path,
                    action: :copy,
                    backup: backup
                }
            end

            # Create a template-based configuration
            #
            # @param template [String] Template file name
            # @param target [String] Target file path
            # @param variables [Hash] Variables to substitute in template
            def template(template, target, variables = {})
                template_path = File.join(@source_directory, "templates", template)
                target_path = File.expand_path(target)

                @links << {
                    name: File.basename(template, ".*"),
                    mutable: false,
                    target: target_path,
                    source: template_path,
                    action: :template,
                    variables: variables
                }
            end

            # Validate the dotfiles configuration
            #
            # @return [Boolean] True if valid
            # @raise [ValidationError] If configuration is invalid
            def validate!
                unless Dir.exist?(@source_directory)
                    raise ValidationError, "Source directory does not exist: #{@source_directory}"
                end

                @links.each do |link_config|
                    validate_link_config(link_config)
                end

                true
            end

            private

            # Validate a single link configuration
            #
            # @param link_config [Hash] The link configuration to validate
            # @raise [ValidationError] If link configuration is invalid
            def validate_link_config(link_config)
                name = link_config[:name]
                source = link_config[:source]
                target = link_config[:target]

                raise ValidationError, "Link name cannot be empty" if name.nil? || name.strip.empty?

                raise ValidationError, "Link must have both source and target paths" unless source && target

                # Check if source exists (skip validation for templates as they might not exist yet)
                if link_config[:action] != :template && !File.exist?(source) && !File.directory?(source)
                    raise ValidationError, "Source path does not exist: #{source}"
                end

                # Validate target directory exists or can be created
                target_dir = File.dirname(target)
                return if Dir.exist?(target_dir)

                begin
                    FileUtils.mkdir_p(target_dir)
                rescue Errno::EACCES, Errno::EPERM => e
                    raise ValidationError, "Cannot create target directory #{target_dir}: #{e.message}"
                end
            end
        end
    end
end
