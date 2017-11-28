# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddForeignKeysToDeployments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  FOREIGN_KEYS = [
    [:environment_id, :environments, :cascade],
    [:user_id, :users, :nullify]
  ]

  def up
    connection.execute <<~SQL
      DELETE FROM deployments
      WHERE NOT EXISTS (
        SELECT 1 FROM environments
        WHERE environments.id = deployments.environment_id
      )
    SQL

    FOREIGN_KEYS.each do |column, table, on_delete|
      unless foreign_key_exists?(:deployments, column)
        add_concurrent_foreign_key(:deployments, table, column: column, on_delete: on_delete)
      end
    end
  end

  def down
    FOREIGN_KEYS.each do |column, table, _|
      if foreign_key_exists?(:deployments, column)
        remove_foreign_key :deployments, table
      end
    end
  end

  private

  def foreign_key_exists?(table, column)
    foreign_keys(table).any? do |key|
      key.options[:column] == column.to_s
    end
  end
end
