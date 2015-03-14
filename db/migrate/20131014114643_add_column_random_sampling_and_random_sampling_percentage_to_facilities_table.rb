class AddColumnRandomSamplingAndRandomSamplingPercentageToFacilitiesTable < ActiveRecord::Migration
  def change
    add_column :facilities, :random_sampling, :boolean
    add_column :facilities, :random_sampling_percentage, :string
  end
end
