# typed: strict
# frozen_string_literal: true

require_relative "base"

module Decldots
    module DSL
        module ProgramConfigs
            # Configuration for Tmux program
            class TmuxConfiguration < BaseProgramConfiguration
                extend T::Sig

                sig { params(key: String).void }
                def prefix_key(key)
                    @options[:prefix_key] = key
                end

                sig { params(enabled: T::Boolean).void }
                def enable_mouse(enabled: true)
                    @options[:mouse] = enabled
                end

                sig { params(enabled: T::Boolean).void }
                def enable_vi_mode(enabled: true)
                    @options[:vi_mode] = enabled
                end

                sig { params(limit: Integer).void }
                def history_limit(limit)
                    @options[:history_limit] = limit
                end

                sig { params(index: Integer).void }
                def base_index(index)
                    @options[:base_index] = index
                end

                sig { params(enabled: T::Boolean).void }
                def enable_clipboard(enabled: true)
                    @options[:clipboard] = enabled
                end

                sig { params(bindings: T::Hash[String, String]).void }
                def key_bindings(bindings)
                    @options[:key_bindings] = bindings
                end

                sig { params(enabled: T::Boolean).void }
                def enable_status_bar(enabled: true)
                    @options[:status_bar] = enabled
                end

                sig { params(position: String).void }
                def status_position(position)
                    @options[:status_position] = position
                end

                sig { params(plugins: T::Array[String]).void }
                def plugins(plugins)
                    @options[:plugins] = plugins
                end

                sig { override.void }
                def validate!
                    if @options[:history_limit] && (!@options[:history_limit].is_a?(Integer) || @options[:history_limit] <= 0)
                        raise ValidationError, "History limit must be a positive integer"
                    end

                    if @options[:base_index] && (!@options[:base_index].is_a?(Integer) || @options[:base_index] < 0)
                        raise ValidationError, "Base index must be a non-negative integer"
                    end

                    return unless @options[:status_position] && !%w[top bottom].include?(@options[:status_position])

                    raise ValidationError, "Status position must be 'top' or 'bottom'"
                end
            end
        end
    end
end
