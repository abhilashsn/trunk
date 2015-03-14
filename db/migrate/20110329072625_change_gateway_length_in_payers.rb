class ChangeGatewayLengthInPayers < ActiveRecord::Migration
  def up
    # Rails 3.1 TODO
    # sqls = Array.new
    # sqls << "UPDATE payers SET payers.gateway = NULL"
    # ActiveRecord::Base.establish_connection
    # sqls.each do |sql|
    #   ActiveRecord::Base.connection.execute(sql)
    # end
    change_column :payers, :gateway, :string, :limit => 10
  end

  def down
    change_column :payers, :gateway, :string
  end
end
