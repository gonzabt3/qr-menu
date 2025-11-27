# lib/tasks/embeddings.rake
namespace :embeddings do
  desc 'Generate embeddings for all products that need them'
  task backfill: :environment do
    puts "Starting embeddings backfill..."
    
    total_products = Product.count
    products_needing_embeddings = Product.where(embedding: nil).or(
      Product.where('embedding_generated_at IS NULL OR updated_at > embedding_generated_at')
    )
    
    count = products_needing_embeddings.count
    
    puts "Found #{count} products (out of #{total_products} total) that need embeddings"
    
    if count.zero?
      puts "All products already have up-to-date embeddings!"
      next
    end
    
    progress = 0
    errors = 0
    
    products_needing_embeddings.find_each do |product|
      begin
        ProductEmbeddingJob.perform_later(product.id)
        progress += 1
        
        if progress % 10 == 0
          puts "Enqueued #{progress}/#{count} products..."
        end
      rescue StandardError => e
        errors += 1
        puts "Error enqueuing product #{product.id}: #{e.message}"
      end
    end
    
    puts "\nBackfill complete!"
    puts "Enqueued: #{progress} products"
    puts "Errors: #{errors}" if errors > 0
    puts "\nNote: Jobs are running asynchronously. Check job queue status to monitor progress."
  end

  desc 'Show embedding generation status'
  task status: :environment do
    total = Product.count
    with_embeddings = Product.where.not(embedding: nil).count
    without_embeddings = Product.where(embedding: nil).count
    outdated = Product.where.not(embedding: nil)
                      .where('updated_at > embedding_generated_at')
                      .count
    
    puts "\n=== Embedding Status ==="
    puts "Total products: #{total}"
    puts "With embeddings: #{with_embeddings} (#{(with_embeddings.to_f / total * 100).round(1)}%)"
    puts "Without embeddings: #{without_embeddings}"
    puts "Outdated embeddings: #{outdated}"
    puts "Up to date: #{with_embeddings - outdated}"
    puts "\nAI Provider: #{ENV.fetch('AI_PROVIDER', 'deepseek')}"
    
    api_key_present = case ENV.fetch('AI_PROVIDER', 'deepseek').downcase
                      when 'openai'
                        ENV['OPENAI_API_KEY'].present?
                      else
                        ENV['DEEPSEEK_API_KEY'].present?
                      end
    
    puts "API Key configured: #{api_key_present ? 'Yes' : 'No'}"
  end

  desc 'Regenerate embeddings for specific products by ID'
  task :regenerate, [:product_ids] => :environment do |_t, args|
    if args[:product_ids].blank?
      puts "Usage: rake embeddings:regenerate[1,2,3]"
      puts "Provide comma-separated product IDs"
      next
    end
    
    ids = args[:product_ids].split(',').map(&:strip).map(&:to_i)
    puts "Regenerating embeddings for #{ids.length} product(s)..."
    
    ids.each do |id|
      product = Product.find_by(id: id)
      if product
        ProductEmbeddingJob.perform_later(id)
        puts "Enqueued product #{id}: #{product.name}"
      else
        puts "Product #{id} not found"
      end
    end
    
    puts "\nDone! Jobs are running asynchronously."
  end

  desc 'Clear all embeddings (use with caution)'
  task clear: :environment do
    print "This will clear all embeddings. Are you sure? (yes/no): "
    confirmation = STDIN.gets.chomp
    
    unless confirmation.downcase == 'yes'
      puts "Cancelled."
      next
    end
    
    count = Product.where.not(embedding: nil).count
    Product.update_all(embedding: nil, embedding_generated_at: nil)
    
    puts "Cleared embeddings for #{count} products."
  end
end
