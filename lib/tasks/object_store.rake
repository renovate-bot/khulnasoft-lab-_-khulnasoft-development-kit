# frozen_string_literal: true

namespace :object_store do
  desc 'Setup Object Store default buckets'
  task :setup do
    next unless KDK.config.object_store.enabled?

    KDK.config.object_store.objects.each_value do |data|
      minio = KDK::Services::Minio.new
      bucket_directory = minio.data_dir.join(data['bucket'])

      bucket_directory.mkpath unless bucket_directory.exist?
    end
  end
end
