# frozen_string_literal: true

RSpec.describe Runit::Config do
  let(:kdk_root) { Pathname.new(Dir.mktmpdir(nil, temp_path)) }
  let(:templates_path) { kdk_root.join('support/templates') }
  let(:real_templates_path) { temp_path.parent.join('support/templates') }

  subject { described_class.new(kdk_root) }

  before do
    templates_path.mkpath
    FileUtils.cp_r(real_templates_path, templates_path.parent)
  end

  after do
    FileUtils.rm_rf(kdk_root)
  end

  describe '#stale_service_links' do
    it 'removes unknown symlinks from the services directory' do
      services_dir = kdk_root.join('services')
      service_mock = Struct.new(:name)

      enabled_service_names = %w[svc1 svc2]
      all_services = %w[svc1 svc2 stale]

      enabled_services = enabled_service_names.map { |name| service_mock.new(name) }

      FileUtils.mkdir_p(services_dir)

      all_services.each do |entry|
        File.symlink('/tmp', services_dir.join(entry))
      end

      FileUtils.touch(services_dir.join('should-be-ignored'))

      stale_collection = [services_dir.join('stale')]
      expect(subject.stale_service_links(enabled_services)).to eq(stale_collection)
    end
  end
end
