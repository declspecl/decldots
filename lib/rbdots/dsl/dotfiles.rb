# typed: strict
# frozen_string_literal: true

module Rbdots
    module DSL
        # Dotfiles configuration DSL interface
        class Dotfiles
            extend T::Sig

            sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
            attr_reader :links

            sig { void }
            def initialize
                @links = T.let([], T::Array[T::Hash[Symbol, T.untyped]])
                @source_directory = T.let(File.expand_path("~/.rbdots/dotfiles"), String)
            end

            sig { params(directory: String).void }
            def set_source_directory(directory)
                @source_directory = File.expand_path(directory)
            end

            sig { params(directory: T.nilable(String)).returns(String) }
            def source_directory(directory = nil)
                set_source_directory(directory) if directory
                @source_directory
            end

            sig { params(name: String, mutable: T::Boolean, target: T.nilable(String)).void }
            def link(name, mutable: false, target: nil)
                target_path = target || File.expand_path("~/.config/#{name}")

                @links << {
                    name: name,
                    mutable: mutable,
                    target: target_path,
                    source: File.join(@source_directory, name)
                }
            end

            sig { params(names: T::Array[String], mutable: T::Boolean).void }
            def link_multiple(names, mutable: false)
                names.each { |name| link(name, mutable: mutable) }
            end

            sig { params(name: String, target: T.nilable(String)).void }
            def link_mutable(name, target: nil)
                link(name, mutable: true, target: target)
            end

            sig { params(name: String, target: T.nilable(String)).void }
            def link_immutable(name, target: nil)
                link(name, mutable: false, target: target)
            end

            sig { params(source: String, target: String, backup: T::Boolean).void }
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

            sig { params(template: String, target: String, variables: T::Hash[T.any(String, Symbol), T.untyped]).void }
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

            sig { returns(T::Boolean) }
            def validate!
                unless Dir.exist?(@source_directory)
                    raise Rbdots::ValidationError, "Source directory does not exist: #{@source_directory}"
                end

                @links.each do |link_config|
                    validate_link_config(link_config)
                end

                true
            end

            private

            sig { params(link_config: T::Hash[Symbol, T.untyped]).void }
            def validate_link_config(link_config)
                name = link_config[:name]
                source = link_config[:source]
                target = link_config[:target]

                raise Rbdots::ValidationError, "Link name cannot be empty" if name.nil? || name.to_s.strip.empty?

                raise Rbdots::ValidationError, "Link must have both source and target paths" unless source && target

                # Skip validation for templates as they might not exist yet
                if link_config[:action] != :template && !File.exist?(source) && !File.directory?(source)
                    raise Rbdots::ValidationError, "Source path does not exist: #{source}"
                end

                target_dir = File.dirname(target)
                return if Dir.exist?(target_dir)

                begin
                    FileUtils.mkdir_p(target_dir)
                rescue Errno::EACCES, Errno::EPERM => e
                    raise Rbdots::ValidationError, "Cannot create target directory #{target_dir}: #{e.message}"
                end
            end
        end
    end
end
