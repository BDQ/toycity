class AddGatewayResponseToCctxn < ActiveRecord::Migration
  def self.up
    add_column :creditcard_txns, :gateway_response, :text
  end

  def self.down
    remove_column :creditcard_txns, :gateway_response
  end
end