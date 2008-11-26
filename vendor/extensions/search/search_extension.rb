# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

PRODUCTS_PER_PAGE = 10

class SearchExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/site_search"
 
  # Testing route.
  define_routes do |map|
    map.search_test '/search/test', :controller => 'searches', :action => 'test'
  end

  define_routes do |map|
    map.resources :searches
  end

  def activate
    # Add pagination support for the find_by_sql method inside paginating_find plugin.
    PaginatingFind::ClassMethods.class_eval do
      def paginating_sql_find(count_query, query, options)
 
        # The current page defaults to 1 when not passed.
        options[:current] ||= "1"
 
        count_query = sanitize_sql(count_query)
        query = sanitize_sql(query)
   
        # execute the count query - need to know how many records we're looking at
        count = count_by_sql(count_query)
   
        PagingEnumerator.new(options[:page_size], count, false, options[:current], 1) do |page|
          # calculate the right offset values for current page and page_size
            offset = (options[:current].to_i - 1) * options[:page_size]
            limit = options[:page_size]
   
            # run the actual query - Note: do not include LIMIT statement in your query
          find_by_sql(query + " LIMIT #{offset},#{limit}")
        end
      end
    end
    
    ProductsController.class_eval do
      private

      def collection
        products_per_page = PRODUCTS_PER_PAGE

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

        @collection ||= Product.available.by_name(params[:search]).find(
          :all,
          :conditions => conditions,
          :order => @sort_by,
          :page => {:start => 1, :size => products_per_page, :current => params[:p]},
          :include => :images)
      end
    end

    TaxonsController.class_eval do
      private

      def load_data
        products_per_page = PRODUCTS_PER_PAGE

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

    ApplicationHelper.class_eval do
      # Redefined here to not escape html characters inside the select options, we need to add &nbsp; tags
      # there to change indentation of subitems.
      def options_for_select(container, selected = nil)
        container = container.to_a if Hash === container

        options_for_select = container.inject([]) do |options, element|
          text, value = option_text_and_value(element)
          selected_attribute = ' selected="selected"' if option_value_selected?(value, selected)
          options << %(<option value="#{html_escape(value.to_s)}"#{selected_attribute}>#{text.to_s}</option>)
        end

        options_for_select.join("\n")
      end
    end

    # Add support for internationalization to this extension.
    Globalite.add_localization_source(File.join(RAILS_ROOT, 'vendor/extensions/site_search/lang/ui'))

    # Add the administration link. (Only as a placeholder)
    Admin::ConfigurationsController.class_eval do
      before_filter :add_site_search_link, :only => :index
      def add_site_search_link
        @extension_links << {:link =>  '#' , :link_text => Globalite.localize(:ext_site_search), :description => Globalite.localize(:ext_site_search_description)}
      end
    end
    # admin.tabs.add "Site Search", "/admin/site_search", :after => "Layouts", :visibility => [:all]
    
    # Expire all_taxonomies cache so TaxonChooser::OPTIONS will be fresh.
    
    Admin::TaxonsController.class_eval do
      before_filter :expire_all_taxnonomies, :except => [:index, :show]
      
      def expire_all_taxnonomies
        Rails.cache.delete('all_taxonomies')
      end
    end
    
    Admin::TaxonomiesController.class_eval do
      before_filter :expire_all_taxnonomies, :except => [:index, :show]
      
      def expire_all_taxnonomies
        Rails.cache.delete('all_taxonomies')
      end
    end
  end

  def deactivate
    # admin.tabs.remove "Search"
  end

  def self.require_gems(config)
    config.gem 'activerecord-tableless', :lib => 'tableless'
  end
end