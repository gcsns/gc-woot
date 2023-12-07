class AddStatusToCampaign < ActiveRecord::Migration[6.1]
  def change
    add_column :campaigns, :audience_count, :integer, default: 0
    add_column :campaigns, :sent_count, :integer, default: 0
    add_column :campaigns, :delivered_count, :integer, default: 0
    add_column :campaigns, :read_count, :integer, default: 0
    add_column :campaigns, :failed_count, :integer, default: 0
    add_column :campaigns, :replied_count, :integer, default: 0
    add_column :campaigns, :total_cost, :integer, default: 0
  end
end
