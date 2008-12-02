class SetConfigOptions < ActiveRecord::Migration
  def self.up
    Spree::Config.set(:default_country_id => 96)
    Spree::Config.set(:order_from => "web@toycity.ie")
    Spree::Config.set(:default_locale => "en-IE")
    
    Spree::Config.set(:enable_mail_delivery => true)
    Spree::Config.set(:mail_domain => "10.1.0.11")
 
  end

  def self.down
  end
end