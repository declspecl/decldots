# typed: strict
# frozen_string_literal: true

module Rbdots
    begin
        require "sorbet-runtime"
        VERSION = T.let("0.1.0", String)
    rescue LoadError
        VERSION = "0.1.0"
    end
end
