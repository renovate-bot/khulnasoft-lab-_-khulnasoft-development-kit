# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Gitaly do
  describe '#success?' do
    context 'when the Gitaly internal socket path length is >= the max' do
      it 'returns false' do
        stub_max_gitaly_internal_socket_path_length(1)

        expect(subject.success?).to be_falsey
      end
    end

    context 'when the Gitaly internal socket path length is < the max' do
      it 'returns true' do
        stub_max_gitaly_internal_socket_path_length(999)

        expect(subject.success?).to be_truthy
      end
    end
  end

  describe '#detail' do
    context 'when the Gitaly internal socket path length is >= the max' do
      it 'returns detail content' do
        stub_max_gitaly_internal_socket_path_length(1)

        expect(subject.detail).to match(/please try and reduce the directory depth/)
      end
    end

    context 'when the Gitaly internal socket path length is < the max' do
      it 'returns nil' do
        stub_max_gitaly_internal_socket_path_length(999)

        expect(subject.detail).to be_nil
      end
    end
  end

  def stub_max_gitaly_internal_socket_path_length(value)
    stub_const('KDK::Diagnostic::Gitaly::MAX_GITALY_INTERNAL_SOCKET_PATH_LENGTH', value)
  end
end
