module Edify
  module Commands
    class Speakers < Thor
      include Helpers

      def self.exit_on_failure?
        true
      end

      desc "stale", "List members who have not spoken recently, longest-waiting first"
      long_desc <<~DESC
        Lists members of your unit who have not spoken in sacrament meeting for --months months, or never have,
        longest-waiting first. Members already scheduled to speak, and members whose invitations are paused, are
        left out. Shows names, gender, age group and last-talk dates only.
      DESC
      option :months, type: :numeric, desc: "How many months counts as stale (1-120, default 12)"
      option :limit, type: :numeric, desc: "Most members to list (1-200, default 25)"
      option :group, enum: %w[primary youth adult], desc: "Only this age group"
      option :json, type: :boolean, default: false, desc: "Print the API's JSON instead of a table"
      def stale
        body = api_get("speakers/stale", months: options[:months], limit: options[:limit], group: options[:group])
        return print_json(body) if options[:json]

        say heading(body)
        speakers = body.fetch("speakers")
        return say("Nobody to list.") if speakers.empty?

        rows = speakers.map { |s| [s["name"], s["gender"], s["group"], s["last_talk_date"] || "never"] }
        say Table.render(%w[NAME GENDER GROUP LAST_TALK], rows)
      end

      private

      def heading(body)
        group = body["group"] ? " (#{body['group']} only)" : ""
        "Not spoken since #{body['spoken_before']}, the last #{body['months']} months#{group}:"
      end
    end
  end
end
