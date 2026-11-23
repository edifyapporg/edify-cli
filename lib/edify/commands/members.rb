module Edify
  module Commands
    class Members < Thor
      include Helpers

      FORBIDDEN = "Member search needs a bishopric or clerk role in Edify, " \
                  "the same roles that see the Members page.".freeze

      def self.exit_on_failure?
        true
      end

      desc "search QUERY", "Find members by name"
      long_desc <<~DESC
        Finds members of your unit whose name contains every word of QUERY, in any order and ignoring case. Names are
        recorded as "Last, First", so `edify members search jane smith` finds "Smith, Jane". Shows name, gender and
        age group only.
      DESC
      option :limit, type: :numeric, desc: "Most members to list (1-100, default 25)"
      option :json, type: :boolean, default: false, desc: "Print the API's JSON instead of a table"
      def search(*words)
        raise Thor::Error, "Give part of a name to search for, e.g. `edify members search smith`." if words.empty?

        query = words.join(" ")
        body = api_get("members", q: query, limit: options[:limit], messages: { "forbidden" => FORBIDDEN })
        return print_json(body) if options[:json]

        members = body.fetch("members")
        return say("No members match \"#{body['query']}\".") if members.empty?

        rows = members.map { |m| [m["name"], m["gender"], m["group"]] }
        say Table.render(%w[NAME GENDER GROUP], rows)
      end
    end
  end
end
