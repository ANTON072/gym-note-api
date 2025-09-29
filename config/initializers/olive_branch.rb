Rails.application.config.middleware.use OliveBranch::Middleware,
  inflection: "camel",
  exclude_params: %w[controller action format],
  content_type_check: true
