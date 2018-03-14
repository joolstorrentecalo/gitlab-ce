class CommitEntity < API::Entities::Commit
  expose :author, using: UserEntity

  expose :author_gravatar_url do |commit|
    GravatarService.new.execute(commit.author_email)
  end

  expose :commit_url do |commit|
    project_commit_url(commit.project, commit)
  end

  expose :commit_path do |commit|
    project_commit_path(commit.project, commit)
  end
end
