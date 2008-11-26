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
    TaxonsController.class_eval do
      before_filter :fetch_featured, :only => [:show]  
      def fetch_featured
        @style = object.name.downcase.gsub(" ", "_")
              
    @style  = "nursery_world"
    
        #get related taxons and category taxons
        @category_taxonomy = TaxonChooser::OPTIONS.find{ |tt| tt.type_name == 'Category'}.options
        @toys_taxon = @category_taxonomy.find{ |t| t.name == 'Toys'}
        @nursery_taxon = @category_taxonomy.find{ |t| t.name == 'Nursery World'}
        @games_taxon = @category_taxonomy.find{ |t| t.name == 'GameZone'}
       
        if @style == 'toys'
          @related_taxons = @category_taxonomy[(@category_taxonomy.index(@toys_taxon)+1)..(@category_taxonomy.index(@nursery_taxon)-1)]
        end
        if @style == 'nursery_world'
          @related_taxons = @category_taxonomy[(@category_taxonomy.index(@nursery_taxon)+1)..(@category_taxonomy.index(@games_taxon)-1)]
        end
        if @style == 'gamezone'
          @related_taxons = @category_taxonomy[(@category_taxonomy.index(@games_taxon)+1)..@category_taxonomy.size]
        end
        
        if object.parent.root?
          #Top Level Taxons: Toys, Nursery World, GameZone
          @featured_products_taxon = Taxon.find(3398, :include => :children)
          @featured_products =  @featured_products_taxon.children.detect{ |t| t.name == object.name }.products
          @featured_product = @featured_products[rand(@featured_products.size)]
          @similar_products = find_similar_products(@featured_product, 6)
        else
          products_per_page = 10

          search = Search.new({
            :taxon_id => params[:taxon],
            :min_price => params[:min_price],
            :max_price => params[:max_price],
            :keywords => params[:search]
          })
          # Verify if theres any ondition.
          conditions = search.conditions
          if conditions == [""]
            conditions = ""
          end

          # Define what is allowed.
          sort_params = {
            "price_asc" => "master_price ASC",
            "price_desc" => "master_price DESC",
            "date_asc" => "available_on ASC",
            "date_desc" => "available_on DESC",
            "name_asc" => "name ASC",
            "name_desc" => "name DESC"
          }
          # Set it to what is allowed or default.
          @sort_by = sort_params[params[:sort]] || "name ASC"

          @search_param = "- #{:searching_by.l_with_args({ :search_term => params[:search] })}" if params[:search]

          @products ||= object.products.available.by_name(params[:search]).find(
            :all,
            :conditions => conditions,
            :order => @sort_by,
            :page => {:start => 1, :size => products_per_page, :current => params[:p]},
            :include => :images)
    
        end
        
 
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

    #Set TaxonsController to use it's own view (instead of products/index)
    TaxonsController.show.wants.html do 
        render :template => 'taxons/show.html.erb' 
    end

    #Add Helper methods to display taxons & get product style
    ProductsHelper.class_eval do 
      def print_taxon_cell(taxons, i, style)
        return " " if taxons.size <= i
        
        name = taxons[i].name
        left = (name.scan("&nbsp;").size - 4) * 2
 
        return image_tag("bullets/#{style}_tab.gif", :style => "padding-left: #{left}px;") + link_to(name.gsub("&nbsp;", ""), taxon_path(taxons[i].id))        
      end
    
      def get_style(product)
        top_level_taxons = ["Toys", "Nursery World", "Gamezone"]
        catogory_taxons = product.taxons.find_all{ |t| t.taxonomy_id == 276849395}
        
        catogory_taxons.each do |t|
          if top_level_taxons.include? t.name
            return t.name.downcase.gsub(" ", "_")
          else
            parent = t.parent
            until top_level_taxons.include? parent.name 
              parent = parent.name
            end
             
            return parent.name.downcase.gsub(" ", "_")
          end
        end
        
      end
    end

    #Update Image model with custom thumbnail sizes
    Image.attachment_options[:thumbnails] =  {:small=>"100x100>", :scroller=>"120x125>", :product=>"175x145>", :main=>"345x345>", :mini=>"75x75>"}
    Image.attachment_options[:max_size] = 50.megabyte
    
  end
  
  def deactivate
  end
  
end