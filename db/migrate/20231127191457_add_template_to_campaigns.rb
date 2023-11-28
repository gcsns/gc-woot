class AddTemplateToCampaigns < ActiveRecord::Migration[6.1]
  def change
    add_column :campaigns, :template, :jsonb, default: {}
  end
end
