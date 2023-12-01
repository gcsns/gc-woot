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
    offset += limit
    Campaign.where(id: campaign.id).update(sent_count: offset)
  end

  def send_message_helper(audience_label_ids:)
    offset = defined?(campaign.sent_count) ? campaign.sent_count : 0
    limit = 50
    contacts = Contact.joins(:taggings).where(taggings: { tag_id: audience_label_ids }).distinct.offset(offset).limit(limit)
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
    return unless message_id.nil?

    create_message(to.id, message_id)
  end

  def create_message(contact_id:, message_id:)
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
      status: :queued
    )
  end

  def create_conversation(contact_id:)
    contact_inbox = ContactInbox.where(contact_id: contact_id, inbox_id: campaign.inbox_id)
    conversation_created = Conversation.create!(
      account_id: campaign.account_id,
      inbox_id: campaign.inbox_id,
      updated_at: Time.current,
      created_at: Time.current,
      contact_id: to.id,
      contact_inbox_id: contact_inbox.id
    )
    conversation_created.id
  end

  def format_custom_params(template, contact)
    pattern = /\${\w+}\$\${\w+}/
    contains_placeholder = template.parameters.any? { |param| param.match?(pattern) }
    return template if contains_placeholder

    template.parameters.map! do |param|
      match = param.match(/\${(\w+)}\$\${(\w+)}/)
      if match
        key_name = match[1]
        fallback_value = match[2]
        contact[key_name] || fallback_value
      else
        param
      end
    end
    template
  end
end
