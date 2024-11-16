require 'logger'

class HiFriend::Logger
  class << self
    def info(msg)
      logger.info(msg)
    end

    def error(msg)
      logger.error(msg)
    end

    private def logger
      @logger ||= build_logger
    end

    private def build_logger
      if File.exist?('log/hi_friend.log')
        ::Logger.new('log/hi_friend.log', datetime_format: '%Y-%m-%d %H:%M:%S')
      else
        ::Logger.new('/dev/null')
      end
    end
  end
end
