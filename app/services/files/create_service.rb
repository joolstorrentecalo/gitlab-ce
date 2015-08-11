require_relative "base_service"

module Files
  class CreateService < BaseService
    def execute
      allowed = Gitlab::GitAccess.new(current_user, project).can_push_to_branch?(ref)
    end

    def validate
      super

      file_name = File.basename(@file_path)

      unless file_name =~ Gitlab::Regex.file_name_regex
        raise_error(
          'Your changes could not be committed, because the file name ' +
          Gitlab::Regex.file_name_regex_message
        )
      end

      unless project.empty_repo?
        blob = repository.blob_at_branch(@current_branch, @file_path)

        if blob
          return error("Your changes could not be committed, because file with such name exists")
        end
      end


      new_file_action = Gitlab::Satellite::NewFileAction.new(current_user, project, ref, file_path)
      created_successfully = new_file_action.commit!(
        params[:content],
        params[:commit_message],
        params[:encoding],
        params[:new_branch]
      )

      if created_successfully
        success
      else
        error("Your changes could not be committed, because the file has been changed")
      end
    end
  end
end
