class Campaigns::TriggerBroadcastCampaignJob < ApplicationJob
  queue_as :low

  def perform(message)
    message.trigger!
  end
end
