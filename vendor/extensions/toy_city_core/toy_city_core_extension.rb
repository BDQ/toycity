# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class ToyCityCoreExtension < Spree::Extension
  version "1.0"
  description "Toy City Core"
  url "http://www.toycity.ie"
 
  def activate
    CreditcardTxn.class_eval do
      serialize :gateway_response, ActiveMerchant::Billing::Response
    end

    CreditcardPayment.class_eval do
      def authorize
        gateway = payment_gateway 
        # ActiveMerchant is configured to use cents so we need to multiply order total by 100
        response = gateway.authorize((order.total * 100).to_i, @creditcard, gateway_options)
        gateway_error(response) unless response.success?
        # create a transaction to reflect the authorization
        self.creditcard_txns << CreditcardTxn.new(
          :amount => order.total,
          :response_code => response.authorization,
          :gateway_response => response,
          :txn_type => CreditcardTxn::TxnType::AUTHORIZE
        )
        
        puts response.to_yaml
      end

      def capture
        authorization = find_authorization
        gw = payment_gateway
        
        options = minimal_gateway_options
        options.update(
          :pasref => authorization.gateway_response.params['pasref'],
          :order_id => authorization.gateway_response.params['orderid']
        )
         
        response = gw.capture((order.total * 100).to_i, authorization.response_code, options)
        gateway_error(response) unless response.success?
        self.creditcard_txns.create(:amount => order.total, :response_code => response.authorization, :txn_type => CreditcardTxn::TxnType::CAPTURE)
      end

      def void
        authorization = find_authorization
        
        options = minimal_gateway_options
        options.update(
          :pasref => authorization.gateway_response.params['pasref'],
          :order_id => authorization.gateway_response.params['orderid']
        )
        
        response = payment_gateway.void(authorization.response_code, options)
        gateway_error(response) unless response.success?
        self.creditcard_txns.create(:amount => order.total, :response_code => response.authorization, :txn_type => CreditcardTxn::TxnType::CAPTURE)
      end
    end
    
    # expire cart_count when some adds to cart
    OrdersController.class_eval do
      before_filter :expire_cart_count, :only => [:edit]  
      def expire_cart_count
        Rails.cache.delete('cart_count')
      end
    end
    #add cart_count helps
    Spree::BaseHelper.class_eval do
      def cart_count
        Rails.cache.fetch('cart_count') { session[:order_id].blank? ? 0 : Order.find(session[:order_id], :include => :line_items).line_items.length }
      end
    end
    
    #fetch featured products
    ProductsController.class_eval do
      before_filter :fetch_featured, :only => [:index]  
      def fetch_featured
        @featured_toys = Taxon.find_by_name('Featured Toys', :include => :products).products
        @featured_toy = @featured_toys[rand(@featured_toys.size)]
        @similar_toys = find_similar_products(@featured_toy, 6)
         
        @featured_nurseries = Taxon.find_by_name('Featured Nursery', :include => :products).products
        @featured_nursery = @featured_nurseries[rand(@featured_nurseries.size)]
        @similar_nursery = find_similar_products(@featured_nursery, 6)
        
        @featured_games = Taxon.find_by_name('Featured Games', :include => :products).products
        @featured_game = @featured_games[rand(@featured_games.size)]
        @similar_games = find_similar_products(@featured_game, 6)
        
        @category_taxonomy = TaxonChooser::OPTIONS.find{ |tt| tt.type_name == 'Category'}.options
        @toys_taxon = @category_taxonomy.find{ |t| t.name == 'Toys'}
        @nursery_taxon = @category_taxonomy.find{ |t| t.name == 'Nursery World'}
        @games_taxon = @category_taxonomy.find{ |t| t.name == 'GameZone'}
        
        @toys_taxons = @category_taxonomy[(@category_taxonomy.index(@toys_taxon)+1)..(@category_taxonomy.index(@nursery_taxon)-1)]
        @nursery_taxons = @category_taxonomy[(@category_taxonomy.index(@nursery_taxon)+1)..(@category_taxonomy.index(@games_taxon)-1)]
        @games_taxons = @category_taxonomy[(@category_taxonomy.index(@games_taxon)+1)..@category_taxonomy.size]
      end
      
      def find_similar_products(product, quantity)
        taxons = product.taxons.find_all{ |t| t.taxonomy_id == 276849395}
        all_products = []
        
        taxons.each { |t| all_products = all_products + t.products}
        
        if all_products.size <= quantity
          return all_products
        else
          similar_products = []
          
          while similar_products.size < quantity
            product = all_products[rand(all_products.size)]
            similar_products << product unless similar_products.include? product
          end
          
          return similar_products
        end
        
      end
      
    end

    #Add Helper method to display taxons
    ProductsHelper.class_eval do
      def print_taxon_cell(taxons, i, style)
        return " " if taxons.size <= i
        
        name = taxons[i].name
        left = (name.scan("&nbsp;").size - 4) * 2
 
        return image_tag("bullets/#{style}_tab.gif", :style => "padding-left: #{left}px;") + link_to(name.gsub("&nbsp;", ""), taxon_path(taxons[i].id))        
      end
    end
  end
  
  def deactivate
  end
  
end