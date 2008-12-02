# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class ToyCityCoreExtension < Spree::Extension
  version "1.0"
  description "Toy City Core"
  url "http://www.toycity.ie"
  
  module TaxonMethods  

    def get_style_from_path(params)
      case params[1]

      when "toys", "nursery-world", "gamezone"
        @style = params[1]
        @top_level = true if params.size == 2

      when "age", "brand"

        @style = "toys"
      else

        @style = session[:style] ? session[:style] : "toys"
      end

      session[:style] = @style
    end
    
    def get_related_taxons
      #get related taxons and category taxons
      @category_taxonomy = TaxonChooser::OPTIONS.find{ |tt| tt.type_name == 'Category'}.options
      @toys_taxon = @category_taxonomy.find{ |t| t.name == 'Toys'}
      @nursery_taxon = @category_taxonomy.find{ |t| t.name == 'Nursery World'}
      @games_taxon = @category_taxonomy.find{ |t| t.name == 'GameZone'}
     
      if @style == 'toys'
        @related_taxons = @category_taxonomy[(@category_taxonomy.index(@toys_taxon)+1)..(@category_taxonomy.index(@nursery_taxon)-1)]
      end
      if @style == 'nursery-world'
        @related_taxons = @category_taxonomy[(@category_taxonomy.index(@nursery_taxon)+1)..(@category_taxonomy.index(@games_taxon)-1)]
      end
      if @style == 'gamezone'
        @related_taxons = @category_taxonomy[(@category_taxonomy.index(@games_taxon)+1)..@category_taxonomy.size]
      end
    end
  end
  
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
      before_filter :expire_cart_count, :only => [:edit, :checkout]  
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
      include TaxonMethods
      
      def show
        @taxon = Taxon.find_by_permalink(params[:id].join("/") + "/")

        get_style_from_path(params[:id])
    
        get_related_taxons()

             
        # Define sorting options
        sort_params = {
          "price_asc" => "master_price ASC",
          "price_desc" => "master_price DESC",
          "date_asc" => "available_on ASC",
          "date_desc" => "available_on DESC",
          "name_asc" => "name ASC",
          "name_desc" => "name DESC"
        }
        # Set default sorting
        @sort_by = sort_params[params[:sort]] || "name ASC"      
        
        if @top_level
          #Top Level Taxons: Toys, Nursery World, GameZone
          @featured_products_taxon = Taxon.find(3398, :include => :children)
          @featured_products =  @featured_products_taxon.children.detect{ |t| t.name == object.name }.products
          @featured_product = @featured_products[rand(@featured_products.size)]
          @featured_products.to_a.delete(@featured_product)
          @similar_products = find_similar_products(@featured_product, 6)
        
          products_per_page = PRODUCTS_PER_PAGE
          
          if params.has_key? "search"
            search = Search.new({
              :min_price => params[:min_price],
              :max_price => params[:max_price],
              :keywords => params[:search]
            })
            
            # Verify if theres any ondition.
            conditions = search.conditions
            if conditions == [""]
              conditions = ""
            end
            
            @search_param = "- #{:searching_by.l_with_args({ :search_term => params[:search] })}" 

            @products = Product.available.by_name(params[:search]).find(
              :all,
              :conditions => conditions,
              :order => @sort_by,
              :page => {:start => 1, :size => products_per_page, :current => params[:p]},
              :include => :images)
          end
        
        else
          @products = object.products.available.by_name(params[:search]).find(
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
         
      def load_data
        
      end
      
    end

    #Set TaxonsController to use it's own view (instead of products/index)
    TaxonsController.show.wants.html do 
        render :template => 'taxons/show.html.erb' 
    end

    #set style for Products show
    ProductsController.class_eval do
      before_filter :fetch_related, :only => [:show]  
      helper :orders
      include TaxonMethods
       
      def fetch_related
        get_style_from_path(params[:taxon_path])
        
        get_related_taxons()
      end
    end
    
    #redirct index method to root_path
    ProductsController.index.wants.html do
         redirect_to root_path
    end

    #Add Helper methods to display taxons & get product style
    ProductsHelper.class_eval do 
      def print_taxon_cell(taxons, i, style)
        return " " if taxons.size <= i
        
        name = taxons[i].name
        left = (name.scan("&nbsp;").size - 4) * 2
 
        return image_tag("bullets/#{style}_tab.gif", :style => "padding-left: #{left}px;") + link_to(name.gsub("&nbsp;", ""), seo_url(taxons[i]))        
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
         
      def get_brand(product)
          brand = product.taxons.to_a.find {|t| t.taxonomy_id == 276849399}
          return "" if brand.nil?
          
          if FileTest.exists? "public/images/brands/#{brand.name.downcase.gsub(" ", "_")}.jpg"
            
            return link_to(image_tag("brands/#{brand.name.downcase.gsub(" ", "_")}.jpg", :alt => brand.name), "/t/#{brand.permalink}")
          else
            return "Brand: " + link_to(brand.name, "/t/#{brand.permalink}")
          end
      end
    end
    
    #Helper to get top level taxon for product
    OrdersHelper.class_eval do
      def get_top_taxon(product)
        top_level_taxons = ["Toys", "Nursery World", "Gamezone"]
        catogory_taxons = product.taxons.find_all{ |t| t.taxonomy_id == 276849395}
        
        catogory_taxons.each do |t|
          if top_level_taxons.include? t.name
            return t
          else
            parent = t.parent
            until top_level_taxons.include? parent.name 
              parent = parent.name
            end
             
            return parent
          end
        end
        
      end
    end

    #Update Image model with custom thumbnail sizes
    Image.attachment_options[:thumbnails] =  {:small=>"100x100>", :scroller=>"120x125>", :product=>"175x145>", :main=>"345x345>", :mini=>"75x75>"}
    Image.attachment_options[:max_size] = 50.megabyte

    #Overrider breadcrumbs helper
    TaxonsHelper.class_eval do
      def breadcrumbs(taxon)
        crumbs = "<p>"
      
        unless taxon
          crumbs += link_to t('Home'), seo_url(Taxon.find(3322))
          return crumbs += "</p>"
        end
        
        taxons = taxon.ancestors.reject {|t| t.name == "Category"}
        unless taxons.empty?
          crumbs += taxons.reverse.collect { |ancestor| link_to ancestor.name, seo_url(ancestor) }.join(" > ")
          crumbs += " > "
        end
        crumbs += link_to taxon.name, seo_url(taxon)
        crumbs += "</p>"
      end
    end
    
    #Add before_validation method to complete required field that
    #we don't need or want (zipcode and phone)
    Address.class_eval do
      before_validation :complete_fields
      
      def complete_fields
        self.zipcode ||= "EIRE"
        self.phone = "N/A" if self.phone.empty? 
      end
    end
    
    #Add hoptoad exception handling
    ApplicationController.class_eval do
   
    end
      
  end
  
  def deactivate
  end
  
end