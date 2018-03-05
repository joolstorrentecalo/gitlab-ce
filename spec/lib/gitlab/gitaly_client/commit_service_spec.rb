require 'spec_helper'

describe Gitlab::GitalyClient::CommitService do
  let(:project) { create(:project, :repository) }
  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.disk_path + '.git' }
  let(:repository) { project.repository }
  let(:repository_message) { repository.gitaly_repository }
  let(:revision) { '913c66a37b4a45b9769037c55c2d238bd0942d2e' }
  let(:commit) { project.commit(revision) }
  let(:client) { described_class.new(repository) }

  describe '#diff_from_parent' do
    context 'when a commit has a parent' do
      it 'sends an RPC request with the parent ID as left commit' do
        request = Gitaly::CommitDiffRequest.new(
          repository: repository_message,
          left_commit_id: 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660',
          right_commit_id: commit.id,
          collapse_diffs: true,
          enforce_limits: true,
          **Gitlab::Git::DiffCollection.collection_limits.to_h
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_diff).with(request, kind_of(Hash))

        client.diff_from_parent(commit)
      end
    end

    context 'when a commit does not have a parent' do
      it 'sends an RPC request with empty tree ref as left commit' do
        initial_commit = project.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863').raw
        request        = Gitaly::CommitDiffRequest.new(
          repository: repository_message,
          left_commit_id: '4b825dc642cb6eb9a060e54bf8d69288fbee4904',
          right_commit_id: initial_commit.id,
          collapse_diffs: true,
          enforce_limits: true,
          **Gitlab::Git::DiffCollection.collection_limits.to_h
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_diff).with(request, kind_of(Hash))

        client.diff_from_parent(initial_commit)
      end
    end

    it 'returns a Gitlab::GitalyClient::DiffStitcher' do
      ret = client.diff_from_parent(commit)

      expect(ret).to be_kind_of(Gitlab::GitalyClient::DiffStitcher)
    end

    it 'encodes paths correctly' do
      expect { client.diff_from_parent(commit, paths: ['encoding/test.txt', 'encoding/テスト.txt', nil]) }.not_to raise_error
    end
  end

  describe '#commit_deltas' do
    context 'when a commit has a parent' do
      it 'sends an RPC request with the parent ID as left commit' do
        request = Gitaly::CommitDeltaRequest.new(
          repository: repository_message,
          left_commit_id: 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660',
          right_commit_id: commit.id
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_delta).with(request, kind_of(Hash)).and_return([])

        client.commit_deltas(commit)
      end
    end

    context 'when a commit does not have a parent' do
      it 'sends an RPC request with empty tree ref as left commit' do
        initial_commit = project.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863')
        request        = Gitaly::CommitDeltaRequest.new(
          repository: repository_message,
          left_commit_id: '4b825dc642cb6eb9a060e54bf8d69288fbee4904',
          right_commit_id: initial_commit.id
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_delta).with(request, kind_of(Hash)).and_return([])

        client.commit_deltas(initial_commit)
      end
    end
  end

  describe '#between' do
    let(:from) { 'master' }
    let(:to) { '4b825dc642cb6eb9a060e54bf8d69288fbee4904' }

    it 'sends an RPC request' do
      request = Gitaly::CommitsBetweenRequest.new(
        repository: repository_message, from: from, to: to
      )

      expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:commits_between)
        .with(request, kind_of(Hash)).and_return([])

      described_class.new(repository).between(from, to)
    end
  end

  describe '#tree_entries' do
    let(:path) { '/' }

    it 'sends a get_tree_entries message' do
      expect_any_instance_of(Gitaly::CommitService::Stub)
        .to receive(:get_tree_entries)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([])

      client.tree_entries(repository, revision, path, false)
    end

    context 'with UTF-8 params strings' do
      let(:revision) { "branch\u011F" }
      let(:path) { "foo/\u011F.txt" }

      it 'handles string encodings correctly' do
        expect_any_instance_of(Gitaly::CommitService::Stub)
          .to receive(:get_tree_entries)
          .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
          .and_return([])

        client.tree_entries(repository, revision, path, false)
      end
    end
  end

  describe '#commit_count' do
    before do
      expect_any_instance_of(Gitaly::CommitService::Stub)
        .to receive(:count_commits)
        .with(gitaly_request_with_path(storage_name, relative_path),
              kind_of(Hash))
        .and_return([])
    end

    it 'sends a commit_count message' do
      client.commit_count(revision)
    end

    context 'with UTF-8 params strings' do
      let(:revision) { "branch\u011F" }
      let(:path) { "foo/\u011F.txt" }

      it 'handles string encodings correctly' do
        client.commit_count(revision, path: path)
      end
    end
  end

  describe '#find_commit' do
    let(:revision) { '4b825dc642cb6eb9a060e54bf8d69288fbee4904' }

    it 'sends an RPC request' do
      request = Gitaly::FindCommitRequest.new(
        repository: repository_message, revision: revision
      )

      expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commit)
        .with(request, kind_of(Hash)).and_return(double(commit: nil))

      described_class.new(repository).find_commit(revision)
    end

  end

  describe '#patch' do
    let(:request) do
      Gitaly::CommitPatchRequest.new(
        repository: repository_message, revision: revision
      )
    end
    let(:response) { [double(data: "my "), double(data: "diff")] }

    subject { described_class.new(repository).patch(revision) }

    it 'sends an RPC request' do
      expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_patch)
        .with(request, kind_of(Hash)).and_return([])

      subject
    end

    it 'concatenates the responses data' do
      allow_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_patch)
        .with(request, kind_of(Hash)).and_return(response)

      expect(subject).to eq("my diff")
    end
  end

  describe '#commit_stats' do
    let(:request) do
      Gitaly::CommitStatsRequest.new(
        repository: repository_message, revision: revision
      )
    end
    let(:response) do
      Gitaly::CommitStatsResponse.new(
        oid: revision,
        additions: 11,
        deletions: 15
      )
    end

    subject { described_class.new(repository).commit_stats(revision) }

    it 'sends an RPC request' do
      expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:commit_stats)
        .with(request, kind_of(Hash)).and_return(response)

      expect(subject.additions).to eq(11)
      expect(subject.deletions).to eq(15)
    end
  end

  describe 'commit caching' do
    set(:project) { create(:project, :repository) }

    subject { described_class.new(repository) }

    context 'when the request store is activated', :request_store do
      it 'requests the commit from Gitaly' do
        expect { subject.find_commit(revision) }.to change { Gitlab::GitalyClient.get_request_count }.by(1)
      end

      it 'caches based on commit oid' do
        subject.find_commit(revision)

        expect { subject.find_commit(revision) }.not_to change { Gitlab::GitalyClient.get_request_count }
      end

      context 'when the commit was requested on another instance' do
        it 'hits the caches' do
          commits = subject.find_all_commits(ref: 'master', max_count: 10)

          expect do
            described_class.new(repository).find_commit(commits.sample.id)
          end.not_to change { Gitlab::GitalyClient.get_request_count }
        end
      end

      context 'when the revision is a branch name' do
        let(:revision) { 'master' }

        it 'produces cache misses' do
          subject.find_commit(revision)

          expect { subject.find_commit(revision) }.to change { Gitlab::GitalyClient.get_request_count }.by(1)
        end
      end
    end
  end
end
