# typed: strict
# frozen_string_literal: true

require_relative "base"

module Decldots
    module DSL
        module ProgramConfigs
            # Configuration for Vim program
            class VimConfiguration < BaseProgramConfiguration
                extend T::Sig

                sig { params(enabled: T::Boolean).void }
                def enable_syntax_highlighting(enabled: true)
                    @options[:syntax_highlighting] = enabled
                end

                sig { params(enabled: T::Boolean).void }
                def enable_line_numbers(enabled: true)
                    @options[:line_numbers] = enabled
                end

                sig { params(width: Integer).void }
                def tab_width(width)
                    @options[:tab_width] = width
                end

                sig { params(enabled: T::Boolean).void }
                def expand_tabs(enabled: true)
                    @options[:expand_tabs] = enabled
                end

                sig { params(theme: String).void }
                def color_scheme(theme)
                    @options[:color_scheme] = theme
                end

                sig { params(enabled: T::Boolean).void }
                def enable_mouse(enabled: true)
                    @options[:mouse] = enabled
                end

                sig { params(disabled: T::Boolean).void }
                def disable_mouse(disabled: true)
                    @options[:mouse] = !disabled
                end

                sig { params(key: Symbol, command: String).void }
                def set_key_mapping(key, command)
                    @options[:key_mappings] ||= {}
                    @options[:key_mappings][key] = command
                end

                sig { override.void }
                def validate!
                    return unless @options[:tab_width] && (!@options[:tab_width].is_a?(Integer) || @options[:tab_width] <= 0)

                    raise ValidationError, "Tab width must be a positive integer"
                end
            end
        end
    end
end
