class AddEnqueuedCountToDataImport < ActiveRecord::Migration[6.1]
  def change
    add_column :campaigns, :enqueued_count, :integer, default: 0
  end
end
