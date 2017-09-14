class CleanupDeploymentsSchema < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  NOT_NULL_COLUMNS = %i[deployable_id deployable_type created_at updated_at]
  TIME_COLUMNS = %i[created_at updated_at]

  def up
    NOT_NULL_COLUMNS.each do |column|
      change_column_null :deployments, column, false
    end

    TIME_COLUMNS.each do |column|
      change_column :deployments, column, :datetime_with_timezone
    end
  end

  def down
    NOT_NULL_COLUMNS.each do |column|
      change_column_null :deployments, column, true
    end

    TIME_COLUMNS.each do |column|
      change_column :deployments, column, :datetime # rubocop: disable Migration/Datetime
    end
  end
end
