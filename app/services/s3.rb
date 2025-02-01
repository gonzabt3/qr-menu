class S3
  def initialize
    Aws.config.update({
                        region: ENV['AWS_REGION'],
                        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
                      })
    @bucket = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET_NAME'])
  end

  def upload_image(file, path)
    byebug
    file_name = path

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
