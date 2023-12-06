class TriggerScheduledItemsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    # trigger the scheduled campaign jobs
    Campaign.where(campaign_type: :one_off, campaign_status: :active).where(scheduled_at: 3.days.ago..Time.current).all.each do |campaign|
      Campaigns::TriggerOneoffCampaignJob.perform_later(campaign)
    end

    # trigger whatsapp template messages
    campaigns = Campaign.joins(:inbox).where(inboxes: { channel_type: 'Channel::Whatsapp' }, campaign_type: :broadcast,
                                             campaign_status: :active).limit(1)
    campaigns.each do |campaign|
      Campaigns::TriggerBroadcastCampaignJob.perform_later(campaign)
    end

    # Job to reopen snoozed conversations
    Conversations::ReopenSnoozedConversationsJob.perform_later

    # Job to auto-resolve conversations
    Account::ConversationsResolutionSchedulerJob.perform_later

    # Job to sync whatsapp templates
    Channels::Whatsapp::TemplatesSyncSchedulerJob.perform_later
  end
end
