class Whatsapp::BroadcastMessageService
  pattr_initialize [:campaign!]

  def perform
    raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'Whatsapp' || !campaign.broadcast?
    raise 'Completed Campaign' if campaign.completed?

    audience_label_ids = campaign.audience.pluck('id')
    process_audience(audience_label_ids)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def process_audience(audience_label_ids)
    contact_counts = Contact.joins(:taggings).where(taggings: { tag_id: audience_label_ids }).distinct.count
    if campaign.sent_count >= contact_counts
      Campaign.where(id: campaign.id).update(campaign_status: :completed)
      return
    end
    send_message_helper(audience_label_ids)

    Campaign.where(id: campaign.id).update_all('sent_count = sent_count + 50')
  end

  def send_message_helper(audience_label_ids)
    offset = defined?(campaign.sent_count) ? campaign.sent_count : 0
    contacts = Contact.joins(:taggings).where(taggings: { tag_id: audience_label_ids }).distinct.offset(offset).limit(50)
    contacts.each do |contact|
      next if contact.phone_number.blank?

      template_to_send = format_custom_params(campaign.template, contact)
      symbol_keys_hash = template_to_send.transform_keys(&:to_sym)

      send_message(to: contact, content: symbol_keys_hash)
    end
  end

  # sends using the required channel and provider
  def send_message(to:, content:)
    # store in source
    message_id = channel.send_template(to.phone_number, content)
    return if message_id.nil?

    create_message(to.id, message_id, content)
  end

  def create_message(contact_id, message_id, content)
    conversation_id = create_conversation(contact_id)
    Message.create!(
      campaign_id: campaign.id,
      source_id: message_id,
      account_id: campaign.account_id,
      content: content,
      message_type: :template,
      inbox_id: campaign.inbox_id,
      updated_at: Time.current,
      created_at: Time.current,
      conversation_id: conversation_id,
      status: :enqueued
    )
  end

  def create_conversation(contact_id)
    contact_inbox = ContactInbox.find_by(contact_id: contact_id, inbox_id: campaign.inbox_id)
    conversation_created = Conversation.create!(
      account_id: campaign.account_id,
      inbox_id: campaign.inbox_id,
      updated_at: Time.current,
      created_at: Time.current,
      contact_id: contact_id,
      contact_inbox_id: contact_inbox.id
    )
    conversation_created.id
  end

  def format_custom_params(template, contact)
    params = template['parameters'].dup
    pattern = /\$\w+\$\$\w+/
    contains_placeholder = params.any? { |param| param.match?(pattern) }

    if contains_placeholder
      params = params.map! do |param|
        if /\$\w+\$\$\w+/.match?(param)
          key_name, fallback_value = param.split('$$')
          contact[key_name[1...]] || fallback_value
        else
          param
        end
      end
    end

    processed_params = params.map do |item|
      { type: 'text', text: item }
    end

    {
      :name => template['template']['name'],
      :namespace => template['template']['namespace'],
      :lang_code => template['template']['lang_code'],
      :parameters => processed_params,
      :id => template['template']['id'],
      :button_parameters => template['button_parameters'],
      :attachment_url => template['attachment_url']
    }
  end
end
