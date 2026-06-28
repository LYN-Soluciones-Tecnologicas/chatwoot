# Permanently locks the `disable_branding` feature flag ON for all accounts.
#
# Background: Enterprise's `Internal::ReconcilePlanConfigService` (triggered
# daily at 00:00 UTC by `Internal::CheckNewVersionsJob` via the schedule
# `internal_check_new_versions_job`) calls
# `account.disable_features!(*premium_features)` for every account when
# `ChatwootHub.pricing_plan == 'community'`. Since `disable_branding` is in
# `enterprise/config/premium_features.yml`, self-hosted (community) installs
# get the flag turned off every night.
#
# Stripe webhooks (`Enterprise::Billing::ReconcilePlanFeaturesService`) take
# a similar approach and also wipe `disable_branding` on plan changes.
#
# We override `disable_features!` / `disable_features` on `Account` so that
# any caller (cron, webhook, manual code) trying to disable `disable_branding`
# is silently ignored for that single feature. Other features are unaffected.
#
# Reversal: delete this file and the override is gone.
Rails.application.config.to_prepare do
  Account.class_eval do
    LYN_LOCKED_FEATURES = %w[disable_branding].freeze unless const_defined?(:LYN_LOCKED_FEATURES)

    def disable_features!(*features)
      filtered = features.flatten.map(&:to_s).reject { |f| LYN_LOCKED_FEATURES.include?(f) }
      return if filtered.empty?

      super(*filtered)
    end

    def disable_features(*features)
      filtered = features.flatten.map(&:to_s).reject { |f| LYN_LOCKED_FEATURES.include?(f) }
      return if filtered.empty?

      super(*filtered)
    end
  end
end
