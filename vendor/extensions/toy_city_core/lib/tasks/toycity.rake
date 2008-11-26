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
end