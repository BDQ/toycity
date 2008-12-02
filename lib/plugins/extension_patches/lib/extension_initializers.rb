#Loads any initializsers that might be present inside extensions

extension_paths = Spree::ExtensionLoader.instance.load_extension_roots

extension_paths.each do |extension_path|
    Dir["#{extension_path}/config/initializers/**/*.rb"].sort.each do |initializer|
      RAILS_DEFAULT_LOGGER.info "INFO: Loading initializer #{initializer}"
      load(initializer)
    end
end