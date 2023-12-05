# rubocop:disable Metrics/ClassLength
class Whatsapp::Providers::WhatsappValueFirstService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  # rubocop:disable Metrics/MethodLength
  def send_template(phone_number, template_info)
    response = HTTParty.post(
      api_message_service,
      headers: api_headers,
      body: {
        '@VER': '1.2',
        'DLR': {
          '@URL': ''
        },
        'SMS': [
          {
            '@CODING': '1',
            '@ID': '1',
            '@MSGTYPE': '1',
            '@PROPERTY': '0',
            'text': '',
            '@TEMPLATEINFO': template_body_parameters(template_info),
            '@UDH': '0',
            'ADDRESS': [
              {
                '@FROM': whatsapp_channel.phone_number,
                '@SEQ': '1',
                '@TAG': 'Shopkey internal otp service',
                '@TO': phone_number
              }
            ]
          }
        ],
        'USER': {
          '@CH_TYPE': '4',
          '@UNIXTIMESTAMP': ''
        }
      }.to_json
    )

    process_response(response)
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def sync_templates
    templates = HTTParty.get(
      api_template_fetch,
      headers: api_headers_basic_auth,
      body: "userid=#{whatsapp_channel.provider_config['username']}&status=Approved"
    )
    return true unless templates.success?
    return true unless templates['templatedata'] && templates['templatedata']['totalrecords']

    templates = templates['templatedata']['data']
    final_templates = []
    templates.each do |template|
      final_templates << {
        'category' => template['category'],
        'components' => template['whatsappcomponents'],
        'language' => template['language'],
        'name' => template['templatename'],
        'status' => template['status'],
        'id' => template['templateid'],
        'whatsApp_id' => template['whatsapptemplateid']
      }
    end
    whatsapp_channel.update(message_templates: final_templates, message_templates_last_updated: Time.now.utc)
  end
  # rubocop:enable Metrics/MethodLength

  def validate_provider_config?
    response = HTTParty.post(
      "#{api_token_service}?action=generate",
      headers: api_headers_basic_auth
    )
    whatsapp_channel.provider_config['access_token'] = response['token'] if response.success?
    response.success?
  end

  def api_headers
    { 'Authorization' => "Bearer #{whatsapp_channel.provider_config['access_token']}", 'Content-Type' => 'application/json' }
  end

  def api_headers_basic_auth
    auth_str = Base64.strict_encode64("#{whatsapp_channel.provider_config['username']}:#{whatsapp_channel.provider_config['password']}")
    {
      'Authorization' => "Basic #{auth_str}",
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
  end

  def api_message_service
    "#{api_base_path}/psms/servlet/psms.JsonEservice"
  end

  def api_token_service
    "#{api_base_path}/psms/api/messages/token"
  end

  def api_base_path
    ENV.fetch('API_VALUE_FIRST_URL', 'https://api.myvfirst.com')
  end

  def whatsapp_base_path
    ENV.fetch('WHATSAPP_VALUE_FIRST_URL', 'https://whatsapp.myvfirst.com')
  end

  def api_template_fetch
    "#{whatsapp_base_path}/waba/template/fetch"
  end

  # rubocop:disable Metrics/MethodLength
  def send_text_message(phone_number, _message)
    response = HTTParty.post(
      api_message_service,
      headers: api_headers,
      body: {
        '@VER': '1.2',
        'DLR': {
          '@URL': ''
        },
        'SMS': [
          {
            '@CODING': '1',
            '@ID': '1',
            '@MSGTYPE': '1',
            '@PROPERTY': '0',
            'text': '',
            '@TEMPLATEINFO': template_body_parameters(template_info),
            '@UDH': '0',
            'ADDRESS': [
              {
                '@FROM': whatsapp_channel.phone_number,
                '@SEQ': '1',
                '@TAG': 'Template messsage from chatwoot',
                '@TO': phone_number
              }
            ]
          }
        ],
        'USER': {
          '@CH_TYPE': '4',
          '@UNIXTIMESTAMP': ''
        }
      }.to_json
    )
    process_response(response)
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    caption = message.content unless %w[audio sticker].include?(type)
    filename = attachment.file.filename if type == 'document'

    response = HTTParty.post(
      api_message_service,
      headers: api_headers,
      body: {
        '@VER': '1.2',
        USER: {
          '@CH_TYPE': '4',
          '@UNIXTIMESTAMP': ''
        },
        DLR: {
          '@URL': ''
        },
        SMS: [
          {
            '@UDH': '0',
            '@CODING': '1',
            '@TEXT': filename || '',
            '@CAPTION': caption,
            '@CONTENTTYPE': attachment.try(:file).try(:content_type),
            '@TYPE': type,
            '@MSGTYPE': '4',
            '@MEDIADATA': attachment.download_url,
            '@PROPERTY': '0',
            '@ID': '0789',
            ADDRESS: [
              {
                '@FROM': whatsapp_channel.phone_number,
                '@TO': phone_number,
                '@SEQ': '1',
                '@TAG': 'some client side random data'
              }
            ]
          }
        ]
      }.to_json
    )
    process_response(response)
  end
  # rubocop:enable Metrics/MethodLength

  def process_response(response)
    if response.success?
      response.try(:MESSAGEACK).try(:GUID).try(:GUID)
    else
      Rails.logger.error response.body
      nil
    end
  end

  def template_body_parameters(template_info)
    template_components = [template_info[:id]]

    template_info[:parameters].each do |param|
      template_components << param[:text]
    end
    template_components.join('~')
  end
end
# rubocop:enable Metrics/ClassLength
