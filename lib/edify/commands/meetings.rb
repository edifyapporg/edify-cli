module Edify
  module Commands
    class Meetings < Thor
      include Helpers

      # Checked before any request, so a date argument can never put anything else into a request path.
      ISO_DATE = /\A\d{4}-\d{2}-\d{2}\z/
      CONTRIBUTOR_LABELS = {
        "presider" => "Presiding",
        "conductor" => "Conducting",
        "chorister" => "Chorister",
        "organist" => "Organist",
        "opening_prayer" => "Opening prayer",
        "closing_prayer" => "Closing prayer",
      }.freeze

      def self.exit_on_failure?
        true
      end

      desc "list", "List meetings and their speakers"
      long_desc <<~DESC
        Lists your unit's meetings from --from (default today) through --to (default 84 days later; at most 366 days
        in all), earliest first, with each meeting's type and speakers.
      DESC
      option :from, desc: "First date, YYYY-MM-DD (default today)"
      option :to, desc: "Last date, YYYY-MM-DD (default 84 days after --from)"
      option :json, type: :boolean, default: false, desc: "Print the API's JSON instead of a table"
      def list
        check_date!(:from, options[:from]) if options[:from]
        check_date!(:to, options[:to]) if options[:to]

        body = api_get("meetings", from: options[:from], to: options[:to])
        return print_json(body) if options[:json]

        say "Meetings from #{body['from']} through #{body['to']}:"
        meetings = body.fetch("meetings")
        return say("No meetings in that time.") if meetings.empty?

        rows = meetings.map { |m| [m["date"], humanize(m["meeting_type"]), m["speakers"].join("; ")] }
        say Table.render(%w[DATE TYPE SPEAKERS], rows)
      end

      desc "show DATE", "Show one meeting: who takes part, its talks and its songs"
      long_desc <<~DESC
        Shows your unit's meeting on DATE (YYYY-MM-DD): its type, who presides, conducts, leads the music and prays,
        its talks in order and its songs in program order.
      DESC
      option :json, type: :boolean, default: false, desc: "Print the API's JSON instead of the summary"
      def show(date)
        check_date!(:date, date)

        body = api_get("meetings/#{date}", not_found: "No meeting on #{date}.")
        return print_json(body) if options[:json]

        say "#{body['date']}  #{humanize(body['meeting_type'])}"
        say_section("Program", contributor_lines(body["contributors"]))
        say_section("Talks", body["talks"].map { |t| talk_line(t) })
        say_section("Songs", body["songs"].map { |s| "#{humanize(s['song_type'])}: #{s['title']}" })
      end

      private

      def check_date!(name, value)
        return if value.to_s.match?(ISO_DATE)

        raise Thor::Error, "#{name == :date ? 'DATE' : "--#{name}"} must be a date written as YYYY-MM-DD."
      end

      def contributor_lines(contributors)
        CONTRIBUTOR_LABELS.filter_map { |key, label| "#{label}: #{contributors[key]}" if contributors[key] }
      end

      def talk_line(talk)
        details = [talk["purpose"], talk["topic"] && "\"#{talk['topic']}\""].compact
        [talk["speaker"], *details].join(" - ")
      end

      def say_section(title, lines)
        say ""
        say "#{title}:"
        say(lines.empty? ? "  (none)" : lines.map { |line| "  #{line}" }.join("\n"))
      end

      def humanize(value)
        value.to_s.tr("_", " ").capitalize
      end
    end
  end
end
