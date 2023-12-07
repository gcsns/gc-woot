class AddCampaignIdToDataImport < ActiveRecord::Migration[6.1]
  def change
    add_column :data_imports, :campaign_id, :integer, default: nil
  end
end
