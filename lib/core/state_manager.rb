# typed: strict
# frozen_string_literal: true

require "json"
require "fileutils"

module Decldots
    # Manages state tracking and rollback functionality
    class StateManager
        extend T::Sig

        sig { returns(T::Hash[Symbol, T.untyped]) }
        attr_reader :state

        sig { returns(String) }
        attr_reader :state_dir

        sig { returns(String) }
        attr_reader :state_file

        sig { returns(String) }
        attr_reader :checkpoints_dir

        sig { void }
        def initialize
            require "xdg"

            @state_dir = T.let(XDG::State.new.to_str, String)
            @state_file = T.let(File.join(state_dir, "state.json"), String)
            @checkpoints_dir = T.let(File.join(state_dir, "checkpoints"), String)

            ensure_state_directory_exists
            @state = T.let(load_state, T::Hash[Symbol, T.untyped])
        end

        sig { returns(String) }
        def create_checkpoint
            checkpoint_id = Time.now.strftime("%Y%m%d_%H%M%S")
            checkpoint_file = File.join(checkpoints_dir, "#{checkpoint_id}.json")

            ensure_checkpoints_directory_exists
            File.write(checkpoint_file, JSON.pretty_generate(@state))

            puts "Created checkpoint: #{checkpoint_id}"
            checkpoint_id
        end

        sig { params(checkpoint_id: String).returns(T::Boolean) }
        def rollback_to(checkpoint_id)
            checkpoint_file = File.join(checkpoints_dir, "#{checkpoint_id}.json")

            raise ConfigurationError, "Checkpoint not found: #{checkpoint_id}" unless File.exist?(checkpoint_file)

            checkpoint_state = JSON.parse(File.read(checkpoint_file))
            @state = checkpoint_state
            save_state

            puts "Rolled back to checkpoint: #{checkpoint_id}"
            true
        end

        sig { void }
        def save_state
            File.write(state_file, JSON.pretty_generate(@state))
        end

        sig { returns(T::Hash[Symbol, T.untyped]) }
        def current_state
            @state
        end

        sig { params(adapter_name: Symbol, installed_packages: T::Array[String]).void }
        def update_package_state(adapter_name, installed_packages)
            @state[:packages] ||= {}
            @state[:packages][adapter_name.to_s] = installed_packages
            @state[:last_updated] = Time.now.iso8601
        end

        sig { params(program_name: Symbol, configuration: T::Hash[Symbol, T.untyped]).void }
        def update_program_state(program_name, configuration)
            @state[:programs] ||= {}
            @state[:programs][program_name.to_s] = {
                "last_configured" => Time.now.iso8601,
                "configuration" => configuration
            }
        end

        sig { params(dotfile_name: String, link_info: T::Hash[Symbol, T.untyped]).void }
        def update_dotfile_state(dotfile_name, link_info)
            @state[:dotfiles] ||= {}
            @state[:dotfiles][dotfile_name] = link_info.merge({
                                                                  "last_updated" => Time.now.iso8601
                                                              }
                                                             )
        end

        sig { params(adapter_name: Symbol).returns(T::Array[String]) }
        def get_package_state(adapter_name)
            @state.dig(:packages, adapter_name.to_s) || []
        end

        sig { params(program_name: Symbol).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
        def get_program_state(program_name)
            @state.dig(:programs, program_name.to_s)
        end

        sig { params(dotfile_name: String).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
        def get_dotfile_state(dotfile_name)
            @state.dig(:dotfiles, dotfile_name)
        end

        sig { returns(T::Array[String]) }
        def list_checkpoints
            return [] unless Dir.exist?(checkpoints_dir)

            Dir.entries(checkpoints_dir)
                .select { |file| file.end_with?(".json") }
                .map { |file| File.basename(file, ".json") }
                .sort.reverse
        end

        sig { params(keep_count: Integer).void }
        def cleanup_checkpoints(keep_count = 10)
            checkpoints = list_checkpoints

            return unless checkpoints.length > keep_count

            to_remove = checkpoints[keep_count..]
            to_remove&.each do |checkpoint_id|
                checkpoint_file = File.join(checkpoints_dir, "#{checkpoint_id}.json")
                FileUtils.rm_f(checkpoint_file)
                puts "Removed old checkpoint: #{checkpoint_id}"
            end
        end

        sig { returns(T::Hash[Symbol, T.untyped]) }
        def state_summary
            {
                packages: @state[:packages]&.transform_values(&:length) || {},
                programs: @state[:programs]&.keys || [],
                dotfiles: @state[:dotfiles]&.keys || [],
                last_updated: @state[:last_updated],
                checkpoints_count: list_checkpoints.length
            }
        end

        private

        sig { returns(T::Hash[Symbol, T.untyped]) }
        def load_state
            if File.exist?(state_file)
                JSON.parse(File.read(state_file))
            else
                create_default_state
            end
        rescue JSON::ParserError => e
            puts "Warning: Invalid state file, creating new state. Error: #{e.message}"
            create_default_state
        end

        sig { returns(T::Hash[Symbol, T.untyped]) }
        def create_default_state
            {
                version: "1.0",
                created_at: Time.now.iso8601,
                packages: {},
                programs: {},
                dotfiles: {}
            }
        end

        sig { void }
        def ensure_state_directory_exists
            FileUtils.mkdir_p(state_dir) unless Dir.exist?(state_dir)
        end

        sig { void }
        def ensure_checkpoints_directory_exists
            FileUtils.mkdir_p(checkpoints_dir) unless Dir.exist?(checkpoints_dir)
        end
    end
end
