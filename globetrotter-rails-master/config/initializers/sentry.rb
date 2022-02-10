Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry[:dsn]
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.enabled_environments = %w[production]

  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = 0.1

  # GIT_SHA1 file is expected to be created by rake docker:build
  config.release = ENV.fetch('GIT_SHA1') { `git rev-parse --short HEAD`.strip }
end
