class HealthController < ApplicationController
  # don't need to do any authentication for updates

  # GET /health
  def check
    render json: {
      status: "ok",
      timestamp: Time.current.utc.iso8601
    }
  end
end
