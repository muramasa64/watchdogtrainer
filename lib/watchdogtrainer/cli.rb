require 'watchdogtrainer/client'
require 'thor'
require 'thor/aws'

module Watchdogtrainer
  class CLI < Thor
    include Thor::Aws

    class_option :verbose, type: :boolean, default: false, aliases: [:v]

    desc :setup, "setup something"
    def setup
      client.setup
    end

    private
    def client
      @client ||= Client.new options, aws_configuration
    end
  end
end
