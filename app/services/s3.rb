class S3
    def initialize
      #@s3_client = Aws::S3::Client.new(
      #  region: ENV['AWS_REGION'],
      #  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      #  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
      #)
      #@bucket = ENV['AWS_S3_BUCKET']

      Aws.config.update({
        region: ENV['AWS_REGION'],
        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
        })
        @bucket = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET_NAME'])
    end
  
    def upload_image(file, path)
        byebug
      file_name = path
  
      # Upload the file to S3
      #@s3_client.put_object(
      #  bucket: @bucket,
      #  key: file_name,
      #  body: file.read,
      #  acl: 'public-read' # This will make the file publicly accessible
      #)
      obj = @bucket.object(file_name)
      obj.upload_file(file, acl: 'public-read')
  
      # Return the public URL of the file
      "https://#{@bucket}.s3.amazonaws.com/#{file_name}"
    end
  
    def delete_image(file_name)
      # Delete the file from S3
      @s3_client.delete_object(
        bucket: @bucket,
        key: file_name
      )
    end
  end
  