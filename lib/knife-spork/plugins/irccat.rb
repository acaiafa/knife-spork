require 'knife-spork/plugins/plugin'

module KnifeSpork
  module Plugins
    class Irccat < Plugin
      name :irccat

      TEMPLATES = {
        :upload  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} uploaded #TEAL%{cookbooks}#NORMAL',
        :promote => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} promoted #TEAL%{cookbooks}#NORMAL to %{environment} %{gist}',
        :rolefromfile  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} uploaded role #TEAL%{role_name}#NORMAL %{gist}',
        :roleedit  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} edited role #TEAL%{role_name}#NORMAL %{gist}',
        :rolecreate  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} created role #TEAL%{role_name}#NORMAL %{gist}',
        :roledelete  => '#BOLD#PURPLECHEF:#NORMAL %{organization}%{current_user} deleted role #TEAL%{role_name}#NORMAL %{gist}'
      }

      def perform; end

      def after_upload
        irccat(template(:upload) % {
          :organization => organization,
          :current_user => current_user,
          :cookbooks    => cookbooks.collect { |c| "#{c.name}@#{c.version}" }.join(", ")
        })
      end

      def after_promote_remote
        environments.each do |environment|
          diff = environment_diffs[environment.name]
          env_gist = env_gist(environment, diff) if config.gist
          irccat(template(:promote) % {
            :organization => organization,
            :current_user => current_user,
            :cookbooks    => cookbooks.collect{ |c| "#{c.name}@#{c.version}" }.join(", "),
            :environment  => environment.name,
            :gist         => env_gist
          })
        end
      end

      def after_rolefromfile
        role_gist = role_gist(role_name,role_difference) if config.gist  and !role_difference.empty?
        irccat(template(:rolefromfile) % {
            :organization => organization,
            :current_user => current_user,
            :role_name    => role_name,
            :gist => role_gist
        })
      end

      def after_roleedit
        role_gist = role_gist(role_name,role_difference) if config.gist  and !role_difference.empty?
        irccat(template(:roleedit) % {
            :organization => organization,
            :current_user => current_user,
            :role_name    => role_name,
            :gist => role_gist
        })
      end

      def after_rolecreate
        role_gist = role_gist(role_name,role_difference) if config.gist  and !role_difference.empty?
        irccat(template(:rolecreate) % {
            :organization => organization,
            :current_user => current_user,
            :role_name    => role_name,
            :gist => role_gist
        })
      end

      def after_roledelete
        role_gist = role_gist(role_name,role_difference) if config.gist  and !role_difference.empty?
        irccat(template(:roledelete) % {
            :organization => organization,
            :current_user => current_user,
            :role_name    => role_name,
            :gist => role_gist
        })
      end

      private
      def irccat(message)
        channels.each do |channel|
          begin
            # Write the message using a TCP Socket
            socket = TCPSocket.open(config.server, config.port)
            socket.write("#{channel} #{message}")
          rescue Exception => e
            ui.error 'Failed to post message with irccat.'
            ui.error e.to_s
          ensure
            socket.close unless socket.nil?
          end
        end
      end

      def env_gist(environment, diff)
        msg = "Environment #{environment} uploaded at #{Time.now.getutc} by #{current_user}\n\nConstraints updated on server in this version:\n\n#{diff.collect { |k, v| "#{k}: #{v}\n" }.join}"
        %x[ echo "#{msg}" | #{config.gist}]
      end

      def role_gist(role_name, role_diff)
        msg = "Role #{role_name} changed at #{Time.now.getutc} by #{current_user}\n\nDiff is as follows:\n\n#{role_diff}"
        %x[ echo "#{msg}" | #{config.gist}]
      end

      def channels
        [ config.channel || config.channels ].flatten
      end

      def template(name)
        (config.template && config.template[name]) || TEMPLATES[name]
      end
    end
  end
end
