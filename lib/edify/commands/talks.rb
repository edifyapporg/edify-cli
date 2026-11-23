module Edify
  module Commands
    class Talks < Thor
      include Helpers

      FORBIDDEN = "Listing talks needs a bishopric or clerk role in Edify, " \
                  "the same roles that see the Talks page.".freeze
      # Long topics are cut short in the table; --json always has the whole topic.
      TOPIC_WIDTH = 50

      def self.exit_on_failure?
        true
      end

      desc "list", "List talks, newest first"
      long_desc <<~DESC
        Lists your unit's sacrament meeting talks, newest first, with the meeting date, speaker, purpose and topic.
        Filters can be combined: --speaker (every word must appear in the speaker's name, recorded as "Last, First"),
        --purpose (part of the purpose, e.g. "missionary"), and --from and --to (meeting dates, YYYY-MM-DD).
      DESC
      option :speaker, desc: "Words from the speaker's name"
      option :purpose, desc: "Text the purpose contains, e.g. missionary"
      option :from, desc: "First meeting date, YYYY-MM-DD"
      option :to, desc: "Last meeting date, YYYY-MM-DD"
      option :limit, type: :numeric, desc: "Most talks to list (1-200, default 50)"
      option :json, type: :boolean, default: false, desc: "Print the API's JSON instead of a table"
      def list
        check_date!(:from, options[:from]) if options[:from]
        check_date!(:to, options[:to]) if options[:to]

        body = api_get("talks", speaker: options[:speaker], purpose: options[:purpose], from: options[:from],
                                to: options[:to], limit: options[:limit], messages: { "forbidden" => FORBIDDEN })
        return print_json(body) if options[:json]

        talks = body.fetch("talks")
        return say("No talks match.") if talks.empty?

        rows = talks.map { |t| [t["date"], t["speaker"], t["purpose"], shorten(t["topic"])] }
        say Table.render(%w[DATE SPEAKER PURPOSE TOPIC], rows)
      end

      private

      def shorten(text)
        return text if text.nil? || text.length <= TOPIC_WIDTH

        "#{text[0, TOPIC_WIDTH - 3].rstrip}..."
      end
    end
  end
end
