class AddTemplateToCampaigns < ActiveRecord::Migration[6.1]
  def change
    add_column :campaigns, :template, :jsonb, default: {}
    add_column :campaigns, :template_parameters, :jsonb, default: {}
    # add_column :campaigns, :selection_type, :enum selection_type {"label", "customer", "csv"}
  end
end
