module WSSyncinator
  def self.initialize!
    env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || :development
    ENV['RACK_ENV'] ||= env.to_s

    RailsConfig.load_and_set_settings('./config/settings.yml', "./config/settings.#{env}.yml", './config/settings.local.yml')

    Mongoid.load! File.expand_path('../../config/mongoid.yml',  __FILE__)

    if defined? Raven
      Raven.configure do |config|
        config.dsn = Settings.sentry.url
      end
    end

    Sidekiq.configure_server do |config|
      config.redis = { url: Settings.redis.url, namespace: 'ws-syncinator' }
    end

    Sidekiq.configure_client do |config|
      config.redis = { url: Settings.redis.url, namespace: 'ws-syncinator' }
    end

    TrogdirAPIClient.configure do |config|
      config.scheme = Settings.trogdir.scheme
      config.host = Settings.trogdir.host
      config.port = Settings.trogdir.port
      config.script_name = Settings.trogdir.script_name
      config.version = Settings.trogdir.version
      config.access_id = Settings.trogdir.access_id
      config.secret_key = Settings.trogdir.secret_key
    end

    Weary::Adapter::NetHttpAdvanced.timeout = Settings.trogdir.api_timeout

    require './lib/log'
    require './lib/workers'

    true
  end
end
