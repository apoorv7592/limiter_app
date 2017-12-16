class RateLimiter
  
  def initialize(limiter_app)
    @app = limiter_app
  end

  def call(env)
  	time_window = 60 * 60 #time frame one hour
  	max_request_allowed =100 #max request allowed in time frame
    client_ip = env["REMOTE_ADDR"]
    key = "count:#{client_ip}"
    count = $redis.get(key)
    unless count
      $redis.set(key, 0)
      $redis.expire(key, time_window) #set expiry time of the key in redis
    end
    if count.to_i >= max_request_allowed      
       rate_limit_headers_hash = rate_limit_headers(count, key, time_window)
      [
       429,
       rate_limit_headers_hash,
       [message(rate_limit_headers_hash["X-Rate-Limit-Reset"])]
      ]
    else
      $redis.incr(key)
      status, headers, body = @app.call(env)
      [
       status,
       headers.merge(rate_limit_headers(count.to_i + 1, key, time_window)),
       body
      ]
    end
  end

  private
	def message(n)
	  { :message => "Rate limit exceeded. Try again in #{n} seconds." }.to_json
	end

	def rate_limit_headers(count, key, time_window)
	  ttl = $redis.ttl(key)
	  time = time_window
	  { "X-Rate-Limit-Limit" => 100, "X-Rate-Limit-Remaining" => (100 - count.to_i).to_s, "X-Rate-Limit-Reset" => ttl }
	end
end