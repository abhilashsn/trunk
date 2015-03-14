class ChangeColumnsForEraJobs < ActiveRecord::Migration
  def up
    change_table :era_jobs do |t|
      t.change :payee_name, :string,  :limit => 60, :null => true
      t.change :payee_qualifier, :string, :limit => 2, :null => true
      t.change :payee_address_1, :string, :limit => 55, :null => true
      t.change :payee_city, :string, :limit => 30, :null => true
      t.change :era_addl_payeeid_qualifier, :string, :limit => 2, :null => true
      t.change :era_addl_payeeid, :string, :limit => 50, :null => true
    end
  end

  def down
    change_table :era_jobs do |t|
      t.change :payee_name, :string,  :limit => 60, :null => false
      t.change :payee_qualifier, :string, :limit => 2, :null => false
      t.change :payee_address_1, :string, :limit => 55, :null => false
      t.change :payee_city, :string, :limit => 30, :null => false
      t.change :era_addl_payeeid_qualifier, :string, :limit => 2, :null => false
      t.change :era_addl_payeeid, :string, :limit => 50, :null => false
    end
  end
end