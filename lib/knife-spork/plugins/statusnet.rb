require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class StatusNet < Plugin
      name :statusnet

      def perform; end

      def after_upload
        statusnet "#{organization}#{current_user} uploaded the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")}"
      end

      def after_promote_remote
        statusnet "#{organization}#{current_user} promoted the following cookbooks:\n#{cookbooks.collect{ |c| "  #{c.name}@#{c.version}" }.join("\n")} to #{environments.collect{ |e| "#{e.name}" }.join(", ")}"
      end

      def after_rolefromfile
        statusnet "#{organization}#{current_user} uploaded role #{role_name}"
      end

      def after_roleedit
        statusnet "#{organization}#{current_user} edited role #{role_name}"
      end

      def after_rolecreate
        statusnet "#{organization}#{current_user} created role #{role_name}"
      end

      def after_roledelete
        statusnet "#{organization}#{current_user} deleted role #{role_name}"
      end


      private

      def statusnet(message)
        safe_require 'curb'

        begin
          c = Curl::Easy.new(config.url)
          c.http_auth_types = :basic
          c.username = config.username
          c.password = config.password
          c.post_body = message
          c.perform
        rescue Exception => e
          ui.error 'Something went wrong sending to StatusNet.'
          ui.error e.to_s
        end
      end

    end
  end
end
