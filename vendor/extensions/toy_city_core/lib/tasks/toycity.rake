
namespace :toycity do
  desc "Generate product thumbnails "
  task :generate_thumbnails  => :environment do
    products = Product.find(:all)
    
    products.each do | product |
      product.images.each do | image |

        image.attachment_options[:thumbnails].each do |suffix, size|
          puts "Thumbnailing: #{RAILS_ROOT + '/public/images/products/0000/' + image.id.to_s + '/' + image.filename}"
          puts "Size: #{size}"
          
          thumb = MiniMagick::Image.from_file(RAILS_ROOT + '/public/images/products/0000/' + image.id.to_s + '/' + image.filename)
          thumb.thumbnail(size)
          
          arr =  image.filename.split(".")
          ext = arr.pop
          filename = arr.join(".")
          
          puts "Saving as: #{RAILS_ROOT + '/public/images/products/0000/' + image.id.to_s + '/' + filename + "_" + suffix.to_s + "." + ext}"
          thumb.write(RAILS_ROOT + '/public/images/products/0000/' + image.id.to_s + '/' + filename + "_" + suffix.to_s  + "." + ext)
          puts ""
        end
      end
    end
  end
  
  
  desc "Export Products to CSV File"
  task :export_products => :environment do
    require 'fastercsv'

    products = Product.find(:all)
    puts "Exporting to #{RAILS_ROOT}/products.csv"
    FasterCSV.open("#{RAILS_ROOT}/products.csv", "w") do |csv|
    
      csv << ["id", "name", "description","sku", "master_price" ]

      products.each do |p|
        csv << [p.id,
                p.name.titleize,
                p.description,
                p.sku,
                p.master_price.to_s]
      end
    end

    puts "Export Complete"
  end
  
  desc "Export Products to CSV File"
  task :import_products => :environment do
    require 'fastercsv'
  
    n = 0
    u = 0
  
    FasterCSV.foreach(ENV['file']) do |row|
     
     
      if row[0].nil?
        # Adding new product
        puts "Adding new product: #{row[1]}"
        product = Product.new()
        
        n += 1
      else
        # Updating existing product
        
        next if row[0].downcase == "id"  #skip header row
        
        puts "Updating product: #{row[1]}"
        product = Product.find(row[0])
        
        u += 1
      end
      
      product.name = row[1]
      product.description = row[2]
      product.sku = row[3].to_s
      product.master_price = row[4].to_d
      product.save!
      
    end
  
    puts ""
    puts "Import Completed - Addded: #{n} | Updated #{u} Products"
   end
end