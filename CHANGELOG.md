# Changelog

All notable changes to edify-cli are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `edify members search QUERY [--limit N]`: members whose name contains every word of the query, with gender and age group. Explains which roles can search when yours can't (#17).

## [0.3.0] - 2026-11-23

### Added

- `edify status`: the server and where it comes from, where the token comes from (never the token itself), and whether the server accepts it. Exits 1 when it doesn't (#14).
- `edify logout`: removes the saved login and reminds you to revoke the token in Edify (#14).

## [0.2.0] - 2026-11-23

### Added

- `edify songs recent [--weeks N] [--limit N] [--song-type T]`: the hymns your unit has sung recently, most sung first, with the types each was sung as (#9).
- `edify meetings list [--from DATE] [--to DATE]`: your unit's meetings and their speakers (#9).
- `edify meetings show DATE`: one meeting's program, talks and songs, or "No meeting on DATE." when there isn't one (#9).

### Changed

- Dates given to `meetings` commands are checked as `YYYY-MM-DD` before any request is made (#9).

## [0.1.0] - 2026-11-23

### Added

- `edify login`: save a personal access token, checked against the server. Press Enter at the URL prompt to use https://www.edifyapp.org (#3, #7).
- `edify speakers stale [--months N] [--limit N] [--group G]`: members who haven't spoken recently, longest-waiting first, with gender and age group (#3).
- `edify version` and `edify help`.
- `--json` on data commands, `EDIFY_TOKEN` and `EDIFY_URL` overrides, and API errors on stderr with exit status 1 (#2, #3).
- The login is saved with owner-only permissions, and the token is sent only over HTTPS, except to localhost (#2).

[Unreleased]: https://github.com/edifyapporg/edify-cli/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/edifyapporg/edify-cli/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/edifyapporg/edify-cli/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/edifyapporg/edify-cli/releases/tag/v0.1.0
