require 'aws-sdk'

module Watchdogtrainer
  class Client
    attr_reader :logger

    def initialize(cli_options = {}, aws_configuration = {})
      @cli_options = cli_options
      @logger ||= Logger.new STDOUT

      aws_configuration[:logger] = Logger.new STDOUT if @cli_options[:verbose]

      @sns = Aws::SNS::Resource.new(aws_configuration)
      @lambda = Aws::Lambda::Client.new(aws_configuration)
    end

    def setup
      begin
        topic = sns_topic
        @logger.info "SNS Topic: #{topic.arn}" if @cli_options[:verbose]


      rescue => e
        @logger.error "setup failed: #{e}"
      end
    end

    private
    def sns_topic(topic_name = DEFAULT_NAME)
      topic = @sns.topics.find {|t| %r(#{topic_name}\z).match(t.arn.to_s)}
      unless topic
        topic = @sns.create_topic(name: topic_name)
      end
      topic
    end


    def lambda_function(function_name = DEFAULT_NAME, role_name = DEFAULT_NAME)
      function = nil
      resp = @lambda.list_functions
      resp.on_success do |r|
        function = r.funcnions.find {|f| %r(\A#{function_name}\z).match(f.function_name)}
        unless function
          function = @lambda.create_function(
            function_name: DEFAULT_NAME,
            runtime: 'nodejs',
            role: DEFAULT_NAME,
            handler: 'index.handler',
            code: {zip_file: LambdaTemplate.encoded_zip('path/to/template')},
            description: 'gerenated by watchdogtrainer'
          )
        end
      end
      function
    end
  end
end
