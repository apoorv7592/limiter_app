$redis = Redis.new
$redis_live = Redis.new(host: ENV['LIVE_REDIS_URL'], port: 6379)