class AddCampaignIdMessage < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :campaign_id, :bigint, default: nil
  end
end
