# rubocop:disable Metrics/ClassLength
class Whatsapp::Providers::WhatsappGupShupService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'wb_interactive'
      send_interactive_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, template_info)
    template_data = {
      destination: phone_number,
      source: whatsapp_channel.provider_config['phone_number'],
      template: template_body_parameters(template_info)
    }
    if template_info[:attachment_url]
      file_type = categorize_file_type(template_info[:attachment_url])
      message = {
        type: file_type
      }
      message[file_type] = { link: template_info[:attachment_url] }
      template_data[:message] = message.to_json
    end
    response = HTTParty.post(
      "#{api_base_path_gup_shup}/template/msg",
      headers: api_headers,
      body: URI.encode_www_form(flatten_hash(template_data))
    )
    process_response(response)
  end

  def sync_templates
    gupshup_templates = fetch_whatsapp_templates("#{api_base_path_gup_shup}/template/list/#{whatsapp_channel.provider_config['app_name']}")
    templates = []
    gupshup_templates.each do |template|
      cur_template = convert_to_chatwoot_template(template)
      templates.push(cur_template) if cur_template && cur_template[:status] == 'APPROVED'
    end

    whatsapp_channel.update(message_templates: templates, message_templates_last_updated: Time.now.utc) if templates.present?
  end

  def fetch_whatsapp_templates(url)
    response = HTTParty.get(url, headers: api_headers)
    return [] unless response.success?

    response['templates']
  end

  def next_url(response)
    response['paging'] ? response['paging']['next'] : ''
  end

  def validate_provider_config?
    true
  end

  def api_headers
    { 'apikey' => whatsapp_channel.provider_config['api_key'], 'Content-Type' => 'application/x-www-form-urlencoded' }
  end

  def media_url
    "#{api_base_path_gup_shup}/get-media"
  end

  # TODO: See if we can unify the API versions and for both paths and make it consistent with out facebook app API versions
  def api_base_path_gup_shup
    'https://api.gupshup.io/sm/api/v1'
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{api_base_path_gup_shup}/msg",
      headers: api_headers,
      body: URI.encode_www_form({
                                  'message' => {
                                    'type' => 'text',
                                    'text' => message.content
                                  },
                                  'src.name' => whatsapp_channel.provider_config['app_name'],
                                  'destination' => phone_number,
                                  'source' => whatsapp_channel.provider_config['phone_number'],
                                  'channel' => 'whatsapp'
                                })
    )

    process_response(response)
  end

  def send_interactive_message(phone_number, message)
    response = HTTParty.post(
      "#{api_base_path_gup_shup}/msg",
      headers: api_headers,
      body: URI.encode_www_form({
                                  'message' => {
                                    'content': {
                                      'type': 'text',
                                      'text': message['content_attributes']['body']['text']
                                    },
                                    'type': 'quick_reply',
                                    'msgid': 'qr1',
                                    'options': [{
                                      'type': 'text',
                                      'title': 'First'
                                    }, {
                                      'type': 'text',
                                      'title': 'Second'
                                    }, {
                                      'type': 'text',
                                      'title': 'Third'
                                    }]
                                  }.to_json,
                                  'src.name' => whatsapp_channel.provider_config['app_name'],
                                  'destination' => phone_number,
                                  'source' => whatsapp_channel.provider_config['phone_number'],
                                  'channel' => 'whatsapp'
                                })
    )

    process_response(response)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video sticker].include?(attachment.file_type) ? attachment.file_type : 'file'
    message_content = {
      'type' => type
    }
    if type == 'image'
      message_content['originalUrl'] = attachment.download_url
      message_content['previewUrl'] = attachment.download_url
    else
      message_content['url'] = attachment.download_url
    end

    message_content['caption'] = message.content unless %w[audio sticker].include?(type) || !message.content
    message_content['filename'] = attachment.file.filename if type == 'document'

    response = HTTParty.post(
      "#{api_base_path_gup_shup}/msg",
      headers: api_headers,
      body:
        URI.encode_www_form({
                              'message' => message_content,
                              'src.name' => whatsapp_channel.provider_config['app_name'],
                              'destination' => phone_number,
                              'source' => whatsapp_channel.provider_config['phone_number'],
                              'channel' => 'whatsapp'
                            })
    )

    process_response(response)
  end

  def process_response(response)
    response_body = JSON.parse(response.body)
    if response.success?
      response_body['messageId']
    else
      Rails.logger.error response.body
      nil
    end
  end

  def template_body_parameters(template_info)
    template_params = {
      id: template_info[:id],
      params: template_info[:parameters].map { |info| info[:text].to_s }
    }
    if template_info[:button_parameters].is_a?(Array) && !template_info[:button_parameters].empty?
      template_params[:components].push(*template_info[:button_parameters])
    end
    template_params.to_json
  end

  def convert_to_chatwoot_template(gup_shup_template)
    return unless gup_shup_template['containerMeta']

    meta_container = JSON.parse(gup_shup_template['containerMeta'])

    chatwoot_template = {
      'id' => gup_shup_template['id'],
      'wa_id' => gup_shup_template['externalId'],
      'name' => gup_shup_template['elementName'],
      'status' => gup_shup_template['status'],
      'category' => gup_shup_template['category'],
      'language' => gup_shup_template['languageCode'],
      'components' => [
        {
          'text' => meta_container['data'],
          'type' => 'BODY'
        }
      ]
    }

    if gup_shup_template['templateType']
      header = {
        'type' => 'HEADER',
        'format' => gup_shup_template['templateType']
      }
      if gup_shup_template['templateType'] == 'text'
        header['text'] = meta_container['header']
      else
        header['mediaId'] = meta_container['mediaId']
      end
      chatwoot_template['components'].push(header)
    end

    if meta_container['footer']
      chatwoot_template['components'].push(
        {
          'type' => 'FOOTER',
          'buttons' => meta_container['footer']
        }
      )
    end

    if meta_container['buttons'].is_a?(Array) && !meta_container['buttons'].empty?
      chatwoot_template['components'].push(
        {
          'type' => 'BUTTONS',
          'buttons' => meta_container['buttons']
        }
      )
    end

    chatwoot_template
  end

  def flatten_hash(hash, parent_key = nil)
    hash.each_with_object({}) do |(k, v), result|
      new_key = parent_key ? "#{parent_key}[#{k}]" : k.to_s
      if v.is_a?(Hash)
        result.merge!(flatten_hash(v, new_key))
      else
        result[new_key] = v
      end
    end
  end

  def categorize_file_type(url)
    file_extension = File.extname(URI.parse(url).path).downcase

    extension_to_category = {
      '.jpg' => 'image',
      '.jpeg' => 'image',
      '.png' => 'image',
      '.gif' => 'image',
      '.mp4' => 'video',
      '.avi' => 'video',
      '.mov' => 'video',
      '.wmv' => 'video'
    }

    if extension_to_category.key?(file_extension)
      extension_to_category[file_extension]
    else
      'document'
    end
  end
end
# rubocop:enable Metrics/ClassLength
