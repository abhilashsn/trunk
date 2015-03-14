class CreateBusinessUnitIndicatorLookupFields < ActiveRecord::Migration
  def up
    create_table :business_unit_indicator_lookup_fields do |t|
      t.column :business_unit_indicator, :integer, :limit => 11
      t.column :financial_class, :string
      t.timestamps
    end
    BusinessUnitIndicatorLookupField.create(:business_unit_indicator => 550, :financial_class => 'TSH')
    BusinessUnitIndicatorLookupField.create(:business_unit_indicator => 301, :financial_class => 'HJD')
    BusinessUnitIndicatorLookupField.create(:business_unit_indicator => 400, :financial_class => 'RSK')
  end

  def down
    drop_table :business_unit_indicator_lookup_fields
  end
end
