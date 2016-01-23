module Watchdogtrainer
  module Utils
    def template_path(template_filename)
      File.join(File.dirname(__dir__), template_filename)
    end
  end
end
