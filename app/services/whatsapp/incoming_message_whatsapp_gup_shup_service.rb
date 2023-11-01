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

class Whatsapp::IncomingMessageWhatsappGupShupService < Whatsapp::IncomingMessageBaseService
  def perform
    case processed_params[:type]
    when 'status'
      process_statuses
    when 'message'
      process_messages
    end
  end

  def processed_params
    @processed_params ||= params[:whatsapp]
  end

  def download_attachment_file(attachment_payload)
    url_response = HTTParty.get(attachment_payload['url'])
    inbox.channel.authorization_error! if url_response.unauthorized?

    Down.download(attachment_payload['url']) if url_response.success?
  end

  def process_messages
    return if find_message_by_source_id(@processed_params[:payload][:id])

    set_contact
    return unless @contact

    set_conversation
    create_messages
  end

  def set_contact
    contact_params = @processed_params[:payload][:sender]
    return if contact_params.blank?

    waid = processed_waid(contact_params[:phone])
    store_number = params[:phone_number]
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: { name: contact_params[:name], phone_number: "+#{waid}",
                            store_number: store_number }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def message_type
    result = @processed_params.dig(:payload, :type) == 'contact' ? 'contacts' : @processed_params.dig(:payload, :type)
  end

  def create_messages
    return if unprocessable_message_type?(message_type)

    message = @processed_params.dig(:payload, :payload)
    # TODO: Fix it as per GupShup
    # log_error(message) && return if error_webhook_event?(message)
    if message_type == 'contacts'
      create_contact_messages(message)
    else
      create_regular_message(message)
    end
  end

  def message_content(message)
    # TODO: map interactive messages back to button messages in chatwoot
    message[:text] ||
      message.dig(:button, :text) ||
      message.dig(:interactive, :button_reply, :title) ||
      message.dig(:interactive, :list_reply, :title) ||
      message[:name]
  end

  def attach_files
    return if %w[text button interactive location contacts].include?(message_type)

    attachment_payload = @processed_params.dig(:payload, :payload)
    @message.content ||= attachment_payload[:caption]
    attachment_file = download_attachment_file(attachment_payload)
    return if attachment_file.blank?

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      file: {
        io: attachment_file,
        filename: attachment_file.original_filename,
        content_type: attachment_file.content_type
      }
    )
  end
end