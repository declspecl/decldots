# typed: strict
# frozen_string_literal: true

require "json"
require "fileutils"

module Decldots
    # Represents the application state with proper typing
    # Manages state tracking and rollback functionality
    class StateManager
        extend T::Sig

        sig { returns(State) }
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
            @state = T.let(load_state, State)
        end

        sig { returns(String) }
        def create_checkpoint
            checkpoint_id = Time.now.strftime("%Y%m%d_%H%M%S")
            checkpoint_file = File.join(checkpoints_dir, "#{checkpoint_id}.json")

            ensure_checkpoints_directory_exists
            File.write(checkpoint_file, JSON.pretty_generate(@state.to_hash))

            puts "Created checkpoint: #{checkpoint_id}"
            checkpoint_id
        end

        sig { params(checkpoint_id: String).void }
        def rollback_to!(checkpoint_id)
            checkpoint_file = File.join(checkpoints_dir, "#{checkpoint_id}.json")
            raise Decldots::ConfigurationError, "Checkpoint not found: #{checkpoint_id}" unless File.exist?(checkpoint_file)

            checkpoint_data = JSON.parse(File.read(checkpoint_file))
            @state = State.from_hash(checkpoint_data)
            save_state

            puts "Rolled back to checkpoint: #{checkpoint_id}"
        end

        sig { void }
        def save_state
            File.write(state_file, JSON.pretty_generate(@state.to_hash))
        end

        sig { returns(T::Array[String]) }
        def list_checkpoints
            return [] unless Dir.exist?(checkpoints_dir)

            Dir.entries(checkpoints_dir)
                .select { |file| file.end_with?(".json") }
                .map { |file| File.basename(file, ".json") }
                .sort
                .reverse
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
            summary = @state.summary
            summary[:checkpoints_count] = list_checkpoints.length
            summary
        end

        private

        sig { returns(State) }
        def load_state
            if File.exist?(state_file)
                state_data = JSON.parse(File.read(state_file))
                State.from_hash(state_data)
            else
                State.default
            end
        rescue JSON::ParserError => e
            puts "Warning: Invalid state file, creating new state. Error: #{e.message}"
            State.default
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

    class State
        extend T::Sig

        sig { returns(String) }
        attr_accessor :version

        sig { returns(String) }
        attr_accessor :created_at

        sig { returns(T.nilable(String)) }
        attr_accessor :last_updated

        sig { returns(T::Hash[String, T::Array[String]]) }
        attr_reader :package_managers

        sig { returns(T::Hash[String, T::Hash[String, T.untyped]]) }
        attr_reader :programs

        sig { returns(T::Hash[String, T::Hash[String, T.untyped]]) }
        attr_reader :dotfiles

        sig do
            params(
                version: String,
                created_at: String,
                last_updated: T.nilable(String),
                package_managers: T::Hash[String, T::Array[String]],
                programs: T::Hash[String, T::Hash[String, T.untyped]],
                dotfiles: T::Hash[String, T::Hash[String, T.untyped]]
            ).void
        end
        def initialize(
            version,
            created_at,
            last_updated: nil,
            package_managers: {},
            programs: {},
            dotfiles: {}
        )
            @version = version
            @created_at = created_at
            @last_updated = last_updated
            @package_managers = package_managers
            @programs = programs
            @dotfiles = dotfiles
        end

        sig { params(package_manager_name: Symbol, installed_packages: T::Array[String]).void }
        def update_packages(package_manager_name, installed_packages)
            @package_managers[package_manager_name.to_s] = installed_packages
            @last_updated = Time.now.iso8601
        end

        sig { params(program_name: Symbol, configuration: T::Hash[Symbol, T.untyped]).void }
        def update_program(program_name, configuration)
            @programs[program_name.to_s] = {
                "last_configured" => Time.now.iso8601,
                "configuration" => configuration
            }
        end

        sig { params(dotfile_name: String, link_info: T::Hash[Symbol, T.untyped]).void }
        def update_dotfile(dotfile_name, link_info)
            @dotfiles[dotfile_name] = link_info.merge("last_updated" => Time.now.iso8601)
        end

        sig { returns(T::Hash[Symbol, T.untyped]) }
        def summary
            {
                package_managers: @package_managers.transform_values(&:length),
                programs: @programs.keys,
                dotfiles: @dotfiles.keys,
                last_updated: @last_updated,
                version: @version,
                created_at: @created_at
            }
        end

        sig { returns(T::Hash[String, T.untyped]) }
        def to_hash
            {
                "version" => @version,
                "created_at" => @created_at,
                "last_updated" => @last_updated,
                "package_managers" => @package_managers,
                "programs" => @programs,
                "dotfiles" => @dotfiles
            }
        end

        sig { params(hash: T::Hash[String, T.untyped]).returns(State) }
        def self.from_hash(hash)
            new(
                hash["version"] || "1.0",
                hash["created_at"] || Time.now.iso8601,
                last_updated: hash["last_updated"],
                package_managers: hash["package_managers"] || {},
                programs: hash["programs"] || {},
                dotfiles: hash["dotfiles"] || {}
            )
        end

        sig { returns(State) }
        def self.default
            new(
                "1.0",
                Time.now.iso8601,
                last_updated: nil,
                package_managers: {},
                programs: {},
                dotfiles: {}
            )
        end
    end
end
