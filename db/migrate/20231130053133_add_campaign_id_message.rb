class AddCampaignIdMessage < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :campaign_id, :bigint, default: nil
    add_foreign_key :messages, :campaigns, column: :campaign_id, on_delete: :cascade
  end
end
