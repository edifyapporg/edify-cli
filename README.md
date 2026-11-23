# edify-cli

A command-line client for the [Edify](https://github.com/edifyapporg/edify) API, for ward leaders, power users and coding agents.

It only reads from the API and formats the answer. Who can see what, and which members are included, is decided by the Edify server.

## Install

Requires Ruby 4.0 or newer. The gem is not on RubyGems yet, so install it from this repository:

```sh
git clone https://github.com/edifyapporg/edify-cli.git
cd edify-cli
gem build edify-cli.gemspec
gem install ./edify-cli-*.gem
```

## Log in

1. In Edify ([www.edifyapp.org](https://www.edifyapp.org)), open **Settings > API Tokens**, create a token, and copy it. It is shown only once.
2. Run:

   ```sh
   edify login
   ```

   Press Enter to use the production server, `https://www.edifyapp.org`, or type another Edify server's URL. Then paste the token. The CLI checks them against the server and saves them to `~/.config/edify/config.yml` (or `$XDG_CONFIG_HOME/edify/config.yml`), readable only by you.

To skip the prompts: `edify login --token edify_...` (add `--url http://localhost:3000` for a development server).

To stop using a token, revoke it in Edify under **Settings > API Tokens**.

## Commands

### `edify speakers stale`

Members of your unit who have not spoken in sacrament meeting recently, longest-waiting first. Members already scheduled to speak, and members whose invitations are paused, are left out.

```sh
$ edify speakers stale --months 12 --group youth
Not spoken since 2025-11-23, the last 12 months (youth only):
NAME         GENDER  GROUP  LAST_TALK
Roe, Samuel  male    youth  never
Poe, Ada     female  youth  2024-06-02
```

| Option | Meaning |
|---|---|
| `--months N` | How many months counts as stale, 1 to 120 (default 12) |
| `--limit N` | Most members to list, 1 to 200 (default 25) |
| `--group G` | Only `primary`, `youth` or `adult` |
| `--json` | Print the API's JSON instead of a table |

Needs a bishopric or clerk role in Edify.

### Other commands

- `edify version`
- `edify help [COMMAND]`

## For scripts and coding agents

- Every data command takes `--json`, which prints the API's response unchanged.
- `EDIFY_TOKEN` (and `EDIFY_URL`, if not the production server) override the saved login, so a script can run without `edify login`.
- Errors go to stderr with exit status 1. The message is the API's own, for example `months must be a whole number from 1 to 120.`

## Security

- The token is sent only as an `Authorization: Bearer` header, and only over HTTPS. Plain `http://` is allowed just for `localhost`, for development.
- The saved config file is created with mode `0600` in a `0700` directory.
- Tokens are read-only, and Edify never returns member notes, phone numbers, email addresses, ages or birthdates through the API.

## Development

```sh
bundle install
bundle exec rake    # specs and RuboCop
```

Edify issue: [edifyapporg/edify#320](https://github.com/edifyapporg/edify/issues/320). Part of [#315](https://github.com/edifyapporg/edify/issues/315).

## License

MIT. See [LICENSE.md](LICENSE.md).
