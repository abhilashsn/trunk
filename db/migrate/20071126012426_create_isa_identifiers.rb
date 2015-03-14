class CreateIsaIdentifiers < ActiveRecord::Migration
  def up
    create_table :isa_identifiers do |t|
      t.column :isa_number, :integer
    end
    execute "INSERT INTO isa_identifiers(isa_number) VALUES(0)"
  end

  def down
    drop_table :isa_identifiers
  end
end
