class HomeController < ApplicationController
  #before_action :rate_limiter, only: [:index]

  def index
    render json: { message: "ok"}
  end

  def test
    render json: { message: "not ok"}
  end

  private 
    def rate_limiter
      time_window = 60 * 60 #time frame one hour
      max_request_allowed = 100 #max request allowed in time frame
      client_ip = request.env["REMOTE_ADDR"]
      key = "count:#{client_ip}"
      count = $redis.get(key)
      ttl = $redis.ttl(key)
      unless count
        $redis.set(key, 0)
        $redis.expire(key, time_window) #set expiry time of the key in redis
      end
      if count.to_i >= max_request_allowed
        render :status => 429, :json => {:message => "Rate limit exceeded. Try again in #{ttl} seconds."}
        return
      end
      $redis.incr(key)
      true
    end

end