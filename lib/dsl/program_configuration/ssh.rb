# typed: strict
# frozen_string_literal: true

require_relative "base"

module Decldots
    module DSL
        module ProgramConfigs
            # Configuration for SSH program
            class SshConfiguration < BaseProgramConfiguration
                extend T::Sig

                sig { params(hosts: T::Hash[String, T::Hash[String, T.untyped]]).void }
                def hosts(hosts)
                    @options[:hosts] = hosts
                end

                sig { params(hostname: String, config: T::Hash[String, T.untyped]).void }
                def host(hostname, config)
                    @options[:hosts] ||= {}
                    @options[:hosts][hostname] = config
                end

                sig { params(enabled: T::Boolean).void }
                def enable_compression(enabled: true)
                    @options[:compression] = enabled
                end

                sig { params(timeout: Integer).void }
                def connect_timeout(timeout)
                    @options[:connect_timeout] = timeout
                end

                sig { params(interval: Integer).void }
                def server_alive_interval(interval)
                    @options[:server_alive_interval] = interval
                end

                sig { params(count: Integer).void }
                def server_alive_count_max(count)
                    @options[:server_alive_count_max] = count
                end

                sig { params(enabled: T::Boolean).void }
                def enable_agent_forwarding(enabled: true)
                    @options[:forward_agent] = enabled
                end

                sig { params(enabled: T::Boolean).void }
                def enable_x11_forwarding(enabled: true)
                    @options[:forward_x11] = enabled
                end

                sig { override.void }
                def validate!
                    if @options[:connect_timeout] && (!@options[:connect_timeout].is_a?(Integer) || @options[:connect_timeout] <= 0)
                        raise ValidationError, "Connect timeout must be a positive integer"
                    end

                    if @options[:server_alive_interval] && (!@options[:server_alive_interval].is_a?(Integer) || @options[:server_alive_interval] <= 0)
                        raise ValidationError, "Server alive interval must be a positive integer"
                    end

                    return unless @options[:hosts] && !@options[:hosts].is_a?(Hash)

                    raise ValidationError, "Hosts must be a hash"
                end
            end
        end
    end
end
