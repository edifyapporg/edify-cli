module Edify
  module Commands
    class Songs < Thor
      include Helpers

      SONG_TYPES = %w[opening_hymn sacrament_hymn congregational_hymn musical_number closing_hymn].freeze

      def self.exit_on_failure?
        true
      end

      desc "recent", "List the hymns sung recently, most sung first"
      long_desc <<~DESC
        Lists the hymns your unit has sung in sacrament meeting over the last --weeks weeks, ending today: most sung
        first, then most recently sung, with the types each was sung as. Prelude and postlude are not counted.
      DESC
      option :weeks, type: :numeric, desc: "How many weeks back to count (1-104, default 12)"
      option :limit, type: :numeric, desc: "Most hymns to list (1-200, default 50)"
      option :song_type, enum: SONG_TYPES, desc: "Count only songs sung as this type"
      option :json, type: :boolean, default: false, desc: "Print the API's JSON instead of a table"
      def recent
        body = api_get("songs/recent", weeks: options[:weeks], limit: options[:limit], song_type: options[:song_type])
        return print_json(body) if options[:json]

        say heading(body)
        songs = body.fetch("songs")
        return say("Nothing sung in that time.") if songs.empty?

        rows = songs.map { |s| [s["title"], s["times_sung"], s["last_sung"], s["song_types"].join(", ")] }
        say Table.render(%w[TITLE TIMES LAST_SUNG TYPES], rows)
      end

      private

      def heading(body)
        type = body["song_type"] ? " (#{body['song_type']} only)" : ""
        "Sung since #{body['since']}, the last #{body['weeks']} weeks#{type}:"
      end
    end
  end
end
