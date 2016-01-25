require 'baby_erubis'
require 'zip'

module Watchdogtrainer
  module LambdaTemplate
    def self.zipped_code(template_filename:, region:, aws_account_number:, topic_name:)
      template_path = template_file_path(template_filename)
      output = render_template(template_path, region, aws_account_number, topic_name)
      zip_stream(template_filename, output).read
    end

    private
    def template_file_path(filename, content)
      File.join('../..', File.dirname(__dir__), 'template', filename)
    end

    def zip_stream(filename, content)
      Zip::OutputStream.write_buffer {|zos|
        zos.put_next_entry(filename)
        zos.print(content)
      }.tap(&:rewind)
    end

    def reder_template(template_path:, region:, aws_account_number:, topic_name:)
      template = BabyErubis::Text.new.from_file(tepmalet_path, 'utf-8')
      context = {
        region: region,
        aws_account_number: aws_account_number,
        topic_name: topic_name
      }
      template.render(context)
    end
  end
end
