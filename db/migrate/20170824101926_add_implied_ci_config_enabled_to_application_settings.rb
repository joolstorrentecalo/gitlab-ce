class AddImpliedCiConfigEnabledToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :implied_ci_config_enabled, :boolean, default: false)
  end

  def down
    remove_column :application_settings, :implied_ci_config_enabled, :boolean
  end
end
