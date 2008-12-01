class AppConfiguration < Configuration

  MAIL_AUTH = ['none', 'plain', 'login', 'cram_md5']
  SECURE_CONNECTION_TYPES = ['None','SSL','TLS']

  preference :enable_mail_delivery, :boolean, :default => false
  preference :mail_host, :string, :default => 'localhost'
  preference :mail_domain, :string, :default => 'localhost'
  preference :mail_port, :integer, :default => 25
  preference :mail_auth_type, :string, :default => MAIL_AUTH[0] 
  preference :smtp_username, :string
  preference :smtp_password, :string
  preference :secure_connection_type, :string, :default => SECURE_CONNECTION_TYPES[0] 
  preference :mails_from, :string
  preference :mail_bcc, :string
  preference :order_from, :string, :default => "orders@example.com"
  preference :order_bcc, :string
  preference :store_cc, :boolean, :default => false
  preference :default_locale, :string, :default => 'en-US'
  preference :allow_locale_switching, :boolean, :default => false
  preference :default_country_id, :integer, :default => 96
  preference :allow_backorders, :boolean, :default => true
  preference :show_descendents, :boolean, :default => true
  preference :show_zero_stock_products, :boolean, :default => true

  validates_presence_of :name
  validates_uniqueness_of :name
end
