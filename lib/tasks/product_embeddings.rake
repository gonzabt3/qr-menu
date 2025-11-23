# frozen_string_literal: true

namespace :product_embeddings do
  desc 'Backfill embeddings for all products that do not have them'
  task backfill: :environment do
    if ENV['FEATURE_AI_CHAT_ENABLED'] != 'true'
      puts 'AI chat feature is not enabled. Set FEATURE_AI_CHAT_ENABLED=true to run this task.'
      exit
    end

    # Find products without embeddings
    products_without_embeddings = Product.where(embedding: nil)
                                         .or(Product.where(embedding_generated_at: nil))

    total = products_without_embeddings.count

    if total.zero?
      puts 'All products already have embeddings!'
      exit
    end

    puts "Found #{total} products without embeddings. Enqueuing jobs..."

    products_without_embeddings.find_each do |product|
      ProductEmbeddingJob.perform_async(product.id)
      print '.'
    end

    puts "\n✓ Enqueued #{total} embedding jobs. Run Sidekiq to process them."
    puts '  Command: bundle exec sidekiq -C config/sidekiq.yml'
  end

  desc 'Regenerate embeddings for all products'
  task regenerate_all: :environment do
    if ENV['FEATURE_AI_CHAT_ENABLED'] != 'true'
      puts 'AI chat feature is not enabled. Set FEATURE_AI_CHAT_ENABLED=true to run this task.'
      exit
    end

    total = Product.count

    if total.zero?
      puts 'No products found!'
      exit
    end

    puts "Found #{total} products. Enqueuing jobs to regenerate all embeddings..."

    Product.find_each do |product|
      ProductEmbeddingJob.perform_async(product.id)
      print '.'
    end

    puts "\n✓ Enqueued #{total} embedding jobs. Run Sidekiq to process them."
    puts '  Command: bundle exec sidekiq -C config/sidekiq.yml'
  end
end
