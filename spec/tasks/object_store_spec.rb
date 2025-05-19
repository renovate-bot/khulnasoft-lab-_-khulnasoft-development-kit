# frozen_string_literal: true

RSpec.describe 'rake object_store:setup' do
  let(:minio_service) { KDK::Services::Minio.new }

  before(:all) do
    Rake.application.rake_require('tasks/object_store')
  end

  before do
    minio_service.data_dir.rmtree if minio_service.data_dir.exist?
  end

  context 'with object store disabled' do
    before do
      stub_kdk_yaml({ 'object_store' => { 'enabled' => false } })
    end

    it 'does not create missing bucket directories' do
      task.invoke

      data = Dir[minio_service.data_dir.join('**')]
      expect(data).to be_empty
    end
  end

  context 'with object store enabled' do
    before do
      stub_kdk_yaml({ 'object_store' => { 'enabled' => true } })
    end

    it 'creates missing bucket directories' do
      task.invoke

      data = Dir[minio_service.data_dir.join('**')]
      expect(data).to contain_exactly(
        %r{minio/data/artifacts},
        %r{minio/data/backups},
        %r{minio/data/ci-secure-files},
        %r{minio/data/dependency-proxy},
        %r{minio/data/external-diffs},
        %r{minio/data/gitaly-backups},
        %r{minio/data/lfs},
        %r{minio/data/packages},
        %r{minio/data/pages},
        %r{minio/data/terraform},
        %r{minio/data/uploads}
      )
    end
  end
end
