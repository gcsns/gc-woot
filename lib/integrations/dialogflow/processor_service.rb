class Integrations::Dialogflow::ProcessorService < Integrations::BotProcessorService
  pattr_initialize [:event_name!, :hook!, :event_data!]

  private

  def message_content(message)
    # TODO: might needs to change this to a way that we fetch the updated value from event data instead
    # cause the message.updated event could be that that the message was deleted

    return message.attachments.first.file_url if message.try(:attachments).try(:first).try(:file_url)

    return message.content_attributes['submitted_values']&.first&.dig('value') if event_name == 'message.updated'

    message.content
  end

  def get_response(session_id, message)
    if hook.settings['credentials'].blank?
      Rails.logger.warn "Account: #{hook.try(:account_id)} Hook: #{hook.id} credentials are not present." && return
    end
    Google::Cloud::Dialogflow.configure { |config| config.credentials = hook.settings['credentials'] }
    session_client = Google::Cloud::Dialogflow.sessions
    session = session_client.session_path project: hook.settings['project_id'], session: session_id
    query_input = { text: { text: message, language_code: 'en-US' } }
    response = session_client.detect_intent session: session, query_input: query_input
    if response.present? && response.query_result.fulfillment_text == 'What was that?'
      response = session_client.detect_intent session: session, query_input: query_input
    end
    response
  end

  def process_response(message, response)
    fulfillment_messages = response.query_result['fulfillment_messages']
    fulfillment_messages.each do |fulfillment_message|
      content_params = generate_content_params(fulfillment_message)
      if content_params['action'].present?
        process_action(message, content_params['action'])
      else
        create_conversation(message, content_params)
      end
    end
  end

  def generate_content_params(fulfillment_message)
    text_response = fulfillment_message['text'].to_h
    content_params = { content: text_response[:text].first } if text_response[:text].present?
    content_params ||= fulfillment_message['payload'].to_h
    content_params
  end

  def create_conversation(message, content_params)
    return if content_params.blank?

    conversation = message.conversation
    conversation.messages.create!(content_params.merge({
                                                         message_type: :outgoing,
                                                         account_id: conversation.account_id,
                                                         inbox_id: conversation.inbox_id
                                                       }))
  end
end
