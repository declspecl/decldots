# typed: strict
# frozen_string_literal: true

module Decldots
    module DSL
        # Dotfiles configuration DSL interface
        class Dotfiles
            extend T::Sig

            sig { returns(T::Array[Link]) }
            attr_reader :links

            sig { void }
            def initialize
                @links = T.let([], T::Array[Link])
            end

            sig { params(name: String, to: String, from: T.nilable(String)).void }
            def link(name, to, from: nil)
                @links << Link.new(name, :link, to, from: from)
            end

            sig { params(name: String, to: String, from: T.nilable(String)).void }
            def copy(name, to, from: nil)
                @links << Link.new(name, :copy, to, from: from)
            end

            sig { void }
            def validate!
                unless Dir.exist?(Decldots.source_directory)
                    raise Decldots::ValidationError, "Source directory does not exist: #{Decldots.source_directory}"
                end

                @links.each do |link|
                    validate_link_config!(link)
                end
            end

            private

            sig { params(link: Link).void }
            def validate_link_config!(link)
                name = link.name
                to = link.to
                link.from

                raise Decldots::ValidationError, "Link name cannot be empty" if name.nil? || name.to_s.strip.empty?

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
