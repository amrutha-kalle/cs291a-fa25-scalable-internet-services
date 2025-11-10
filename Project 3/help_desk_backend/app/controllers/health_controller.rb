class HealthController < ApplicationController
  # skip_before_action :authenticate_user, only: [:check]

  # GET /health
  def check
    render json: {
      status: "ok",
      timestamp: Time.current.utc.iso8601
    }
  end
end
