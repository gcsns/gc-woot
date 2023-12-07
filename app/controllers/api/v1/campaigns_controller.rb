class Api::V1::CampaignsController < ApplicationController
  def show
    id = params[:id]
    campaign = Campaign.find(id)
    render json: campaign
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Campaign not found' }, status: :not_found
  end

  def messages
    campaign_id = params[:id]
    limit = params[:limit]
    offset = params[:offset]
    status = params[:status]
    campaign = Campaign.find(campaign_id)
    messages = fetch_messages(campaign_id, limit, offset, status)
    formatted_messages = get_formatted_messages(messages, campaign)
    render json: formatted_messages
  end

  private

  def fetch_messages(id, limit, offset, status)
    messages = if status
                 Message.where({ campaign_id: id, status: status }).limit(limit).offset(offset)
               else
                 Message.where(campaign_id: id).limit(limit).offset(offset)
               end
  end

  def get_formatted_messages(messages, campaign)
    messages.map do |message|
      contact = get_contact_details(message.conversation_id)
      {
        contact_name: contact.name,
        contact_number: contact.phone_number,
        audience: campaign.audience,
        sent_at: message.created_at,
        updated_at: message.updated_at
      }
    end
  end

  def get_contact_details(conversation_id)
    contact = Contact.joins(conversations: :messages).find_by(messages: { conversation_id: conversation_id })
  end
end
