#worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
worker_processes 3

timeout 30
preload_app true

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  @sidekiq_pid ||= spawn("bundle exec sidekiq -c 2")
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection

  Sidekiq.configure_client do |config|
    config.redis = { :size => 1, network_timeout: 5 }
  end

  Sidekiq.configure_server do |config|
    config.redis = { :size => 5, network_timeout: 5 }
    config.failures_max_count = 100
  end

end
