# frozen_string_literal: true

require "json"
require "fileutils"

module Rbdots
    # Manages state tracking and rollback functionality
    class StateManager
        STATE_DIR = File.expand_path("~/.rbdots")
        STATE_FILE = File.join(STATE_DIR, "state.json")
        CHECKPOINTS_DIR = File.join(STATE_DIR, "checkpoints")

        def initialize
            ensure_state_directory_exists
            @state = load_state
        end

        # Create a checkpoint for rollback purposes
        #
        # @return [String] The checkpoint identifier
        def create_checkpoint
            checkpoint_id = Time.now.strftime("%Y%m%d_%H%M%S")
            checkpoint_file = File.join(CHECKPOINTS_DIR, "#{checkpoint_id}.json")

            ensure_checkpoints_directory_exists
            File.write(checkpoint_file, JSON.pretty_generate(@state))

            puts "Created checkpoint: #{checkpoint_id}"
            checkpoint_id
        end

        # Rollback to a specific checkpoint
        #
        # @param checkpoint_id [String] The checkpoint identifier
        # @return [Boolean] True if successful
        def rollback_to(checkpoint_id)
            checkpoint_file = File.join(CHECKPOINTS_DIR, "#{checkpoint_id}.json")

            raise ConfigurationError, "Checkpoint not found: #{checkpoint_id}" unless File.exist?(checkpoint_file)

            checkpoint_state = JSON.parse(File.read(checkpoint_file))
            @state = checkpoint_state
            save_state

            puts "Rolled back to checkpoint: #{checkpoint_id}"
            true
        end

        # Save the current state to disk
        def save_state
            File.write(STATE_FILE, JSON.pretty_generate(@state))
        end

        # Get the current state
        #
        # @return [Hash] The current state
        def current_state
            @state
        end

        # Update package state
        #
        # @param adapter_name [Symbol] The package manager adapter name
        # @param installed_packages [Array<String>] List of installed packages
        def update_package_state(adapter_name, installed_packages)
            @state["packages"] ||= {}
            @state["packages"][adapter_name.to_s] = installed_packages
            @state["last_updated"] = Time.now.iso8601
        end

        # Update program state
        #
        # @param program_name [Symbol] The program name
        # @param configuration [Hash] The program configuration
        def update_program_state(program_name, configuration)
            @state["programs"] ||= {}
            @state["programs"][program_name.to_s] = {
                "last_configured" => Time.now.iso8601,
                "configuration" => configuration
            }
        end

        # Update dotfiles state
        #
        # @param dotfile_name [String] The dotfile name
        # @param link_info [Hash] Information about the link
        def update_dotfile_state(dotfile_name, link_info)
            @state["dotfiles"] ||= {}
            @state["dotfiles"][dotfile_name] = link_info.merge({
                                                                   "last_updated" => Time.now.iso8601
                                                               })
        end

        # Get package state for a specific adapter
        #
        # @param adapter_name [Symbol] The adapter name
        # @return [Array<String>] List of installed packages
        def get_package_state(adapter_name)
            @state.dig("packages", adapter_name.to_s) || []
        end

        # Get program state for a specific program
        #
        # @param program_name [Symbol] The program name
        # @return [Hash, nil] The program state
        def get_program_state(program_name)
            @state.dig("programs", program_name.to_s)
        end

        # Get dotfile state for a specific dotfile
        #
        # @param dotfile_name [String] The dotfile name
        # @return [Hash, nil] The dotfile state
        def get_dotfile_state(dotfile_name)
            @state.dig("dotfiles", dotfile_name)
        end

        # List all available checkpoints
        #
        # @return [Array<String>] List of checkpoint identifiers
        def list_checkpoints
            return [] unless Dir.exist?(CHECKPOINTS_DIR)

            Dir.entries(CHECKPOINTS_DIR)
               .select { |file| file.end_with?(".json") }
               .map { |file| File.basename(file, ".json") }
               .sort.reverse
        end

        # Clean up old checkpoints (keep only the last N)
        #
        # @param keep_count [Integer] Number of checkpoints to keep
        def cleanup_checkpoints(keep_count = 10)
            checkpoints = list_checkpoints

            return unless checkpoints.length > keep_count

            to_remove = checkpoints[keep_count..-1]
            to_remove.each do |checkpoint_id|
                checkpoint_file = File.join(CHECKPOINTS_DIR, "#{checkpoint_id}.json")
                FileUtils.rm_f(checkpoint_file)
                puts "Removed old checkpoint: #{checkpoint_id}"
            end
        end

        # Get state summary for display
        #
        # @return [Hash] Summary of current state
        def state_summary
            {
                packages: @state["packages"]&.transform_values(&:length) || {},
                programs: @state["programs"]&.keys || [],
                dotfiles: @state["dotfiles"]&.keys || [],
                last_updated: @state["last_updated"],
                checkpoints_count: list_checkpoints.length
            }
        end

        private

        # Load state from disk or create default state
        #
        # @return [Hash] The loaded or default state
        def load_state
            if File.exist?(STATE_FILE)
                JSON.parse(File.read(STATE_FILE))
            else
                create_default_state
            end
        rescue JSON::ParserError => e
            puts "Warning: Invalid state file, creating new state. Error: #{e.message}"
            create_default_state
        end

        # Create default state structure
        #
        # @return [Hash] Default state
        def create_default_state
            {
                "version" => "1.0",
                "created_at" => Time.now.iso8601,
                "packages" => {},
                "programs" => {},
                "dotfiles" => {}
            }
        end

        # Ensure the state directory exists
        def ensure_state_directory_exists
            FileUtils.mkdir_p(STATE_DIR) unless Dir.exist?(STATE_DIR)
        end

        # Ensure the checkpoints directory exists
        def ensure_checkpoints_directory_exists
            FileUtils.mkdir_p(CHECKPOINTS_DIR) unless Dir.exist?(CHECKPOINTS_DIR)
        end
    end
end
