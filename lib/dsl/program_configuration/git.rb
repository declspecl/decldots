# typed: strict
# frozen_string_literal: true

require_relative "base"

module Decldots
    module DSL
        module ProgramConfigs
            # Configuration for Git program
            class GitConfiguration < BaseProgramConfiguration
                extend T::Sig

                sig { params(name: String).void }
                def user_name(name)
                    @options[:user_name] = name
                end

                sig { params(email: String).void }
                def user_email(email)
                    @options[:user_email] = email
                end

                sig { params(branch: String).void }
                def default_branch(branch)
                    @options[:default_branch] = branch
                end

                sig { params(enabled: T::Boolean).void }
                def pull_rebase(enabled = true)
                    @options[:pull_rebase] = enabled
                end

                sig { override.void }
                def validate!
                    return if @options.any?

                    raise ValidationError, "Git configuration must specify at least one option"
                end
            end
        end
    end
end
