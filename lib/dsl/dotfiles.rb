# typed: strict
# frozen_string_literal: true

module Decldots
    module DSL
        # Dotfiles configuration DSL interface
        class Dotfiles
            extend T::Sig

            sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
            attr_reader :links

            sig { void }
            def initialize
                @links = T.let([], T::Array[T::Hash[Symbol, T.untyped]])
            end

            sig { params(name: String, mutable: T::Boolean, to: T.nilable(String)).void }
            def link(name, mutable: false, to: nil)
                to_path = to || File.expand_path("~/.config/#{name}")

                @links << {
                    name: name,
                    mutable: mutable,
                    to: to_path
                }
            end

            sig { params(from: String, to: String, backup: T::Boolean).void }
            def copy(from, to, backup: true)
                from_path = File.join(Decldots.source_directory, from)
                to_path = File.expand_path(to)

                @links << {
                    name: File.basename(from),
                    mutable: false,
                    to: to_path,
                    action: :copy,
                    backup: backup
                }
            end

            sig { returns(T::Boolean) }
            def validate!
                unless Dir.exist?(Decldots.source_directory)
                    raise Decldots::ValidationError, "Source directory does not exist: #{Decldots.source_directory}"
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
                to = link_config[:to]

                raise Decldots::ValidationError, "Link name cannot be empty" if name.nil? || name.to_s.strip.empty?

                raise Decldots::ValidationError, "Link must have both source and target paths" unless to

                target_dir = File.dirname(to)
                return if Dir.exist?(target_dir)

                begin
                    FileUtils.mkdir_p(target_dir)
                rescue Errno::EACCES, Errno::EPERM => e
                    raise Decldots::ValidationError, "Cannot create target directory #{target_dir}: #{e.message}"
                end
            end
        end
    end
end
