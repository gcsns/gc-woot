# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/
require 'mime/types'

class MyTempfile < Tempfile
  attr_accessor :original_filename, :content_type

  def initialize(basename, original_filename, *args)
    super(basename, *args)

    @original_filename = original_filename
  end
end

class Whatsapp::IncomingMessageWhatsappAiSensyService < Whatsapp::IncomingMessageBaseService
  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    response = HTTParty.post(inbox.channel.media_url, headers: inbox.channel.api_headers, body: { id: attachment_payload[:id] }.to_json)
    # This url response will be failure if the access token has expired.

    file_extension = MIME::Types[attachment_payload[:mime_type]].first.preferred_extension
    file_name = "chatwoot-whatsapp-file.#{file_extension}"
    parsed_response = JSON.parse(response.read_body)
    file = MyTempfile.new('example', file_name)
    file.content_type = attachment_payload[:mime_type]
    file.binmode
    file << parsed_response['data'].pack('C*')
    file.rewind
    file
  end
end
