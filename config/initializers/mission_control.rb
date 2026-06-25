# Authentication for the Mission Control — Jobs dashboard (mounted at /jobs).
#
# Open locally in development; HTTP Basic auth everywhere else, with credentials
# from env vars. With auth enabled but credentials unset, the dashboard fails
# closed (returns 401), so a deployed instance is never left exposed.
if Rails.env.development?
  MissionControl::Jobs.http_basic_auth_enabled = false
else
  MissionControl::Jobs.http_basic_auth_user = ENV["MISSION_CONTROL_JOBS_HTTP_BASIC_AUTH_USER"]
  MissionControl::Jobs.http_basic_auth_password = ENV["MISSION_CONTROL_JOBS_HTTP_BASIC_AUTH_PASSWORD"]
end
