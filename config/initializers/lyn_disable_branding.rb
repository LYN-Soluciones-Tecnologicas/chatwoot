# Guarantees that the `disable_branding` feature flag stays enabled on every
# account at every Rails boot. Idempotent: if it is already on, the save is
# a no-op for that account; if it has been reset (e.g. by a bit-shift after
# upstream features.yml reordering, a startup script in the deployed image,
# manual toggle, or any other path), the next container start re-enables it.
#
# Runs after Rails has finished initializing so the connection pool and AR
# models are ready. Defensive guards keep it from blowing up when run before
# the schema exists (initial setup, `rails db:create`, tests with empty DB).
Rails.application.config.after_initialize do
  next if Rails.env.test?

  begin
    next unless ActiveRecord::Base.connection.table_exists?('accounts')

    Account.find_each(batch_size: 50) do |account|
      next if account.feature_enabled?('disable_branding')

      account.enable_features!('disable_branding')
      Rails.logger.info("[LYN] Re-enabled disable_branding for account #{account.id}")
    end
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
    # DB not ready (first-time setup, test bootstrap). Skip silently.
  rescue StandardError => e
    Rails.logger.warn("[LYN] disable_branding initializer skipped: #{e.class}: #{e.message}")
  end
end
