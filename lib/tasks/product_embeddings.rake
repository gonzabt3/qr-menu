# lib/tasks/product_embeddings.rake
namespace :product_embeddings do
  desc 'Backfill embeddings for all products without embeddings'
  task backfill: :environment do
    unless ENV['FEATURE_AI_CHAT_ENABLED'] == 'true'
      puts "⚠️  FEATURE_AI_CHAT_ENABLED is not set to 'true'. Skipping backfill."
      exit
    end

    products_without_embeddings = Product.where(embedding: nil)
                                        .or(Product.where(embedding_generated_at: nil))

    total_count = products_without_embeddings.count

    if total_count.zero?
      puts "✓ All products already have embeddings!"
      exit
    end

    puts "Found #{total_count} products without embeddings"
    puts "Enqueueing jobs..."

    enqueued = 0
    products_without_embeddings.find_each do |product|
      ProductEmbeddingJob.perform_async(product.id)
      enqueued += 1
      print "\rEnqueued: #{enqueued}/#{total_count}" if enqueued % 10 == 0
    end

    puts "\n✓ Enqueued #{enqueued} jobs for embedding generation"
    puts "Monitor progress with: bundle exec sidekiq"
  end

  desc 'Regenerate embeddings for all products (force update)'
  task regenerate: :environment do
    unless ENV['FEATURE_AI_CHAT_ENABLED'] == 'true'
      puts "⚠️  FEATURE_AI_CHAT_ENABLED is not set to 'true'. Skipping regeneration."
      exit
    end

    total_count = Product.count

    if total_count.zero?
      puts "⚠️  No products found in database"
      exit
    end

    puts "Found #{total_count} products"
    puts "Enqueueing jobs for regeneration..."

    enqueued = 0
    Product.find_each do |product|
      ProductEmbeddingJob.perform_async(product.id)
      enqueued += 1
      print "\rEnqueued: #{enqueued}/#{total_count}" if enqueued % 10 == 0
    end

    puts "\n✓ Enqueued #{enqueued} jobs for embedding regeneration"
    puts "Monitor progress with: bundle exec sidekiq"
  end

  desc 'Show embedding statistics'
  task stats: :environment do
    total = Product.count
    with_embeddings = Product.where.not(embedding: nil).count
    without_embeddings = total - with_embeddings

    puts "=== Product Embedding Statistics ==="
    puts "Total products: #{total}"
    puts "With embeddings: #{with_embeddings}"
    puts "Without embeddings: #{without_embeddings}"
    
    if total > 0
      percentage = (with_embeddings.to_f / total * 100).round(2)
      puts "Coverage: #{percentage}%"
    end
  end
end
