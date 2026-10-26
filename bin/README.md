# bin

Helper scripts for running the strata. `~/strata-bin` is a symlink to this
directory, so cron jobs and shells use the repo copy directly.

| Script | What it does |
|---|---|
| `add_fob.sh <unit> <fob>` | Adds a fob to a unit in the MESH admin site by running the Playwright `addfob` test from the `WebAutomation` repo. The first argument is the **unit**, not the buzz code. |
| `program_enterphone.sh <buzz> <tel>` | Programs an enterphone entry by dialling the buzzer from an Android phone over `adb`. `<buzz>` is the buzz code (555-965), `<tel>` is the 10-digit local number. If `ENTERPHONE_DISPLAY_HOST` is set (e.g. `pi@enterphone`), it then rebuilds the e-ink directory and sends it to the Pi (see `enterphone-display/`); a failure there only prints a warning. |
| `check_garbage.sh` | Lists the days the "Garbage" fob was used, by querying the `mesh` Postgres database with `psql`. Writes `check_garbage.out`. |
| `fob-log-query.pl` | Joins owners from `Contacts & Roles.xlsx` with fobs in the `mesh` database. |
| `unit-query.pl` | Looks up a unit, buzz code, owner, phone, fob, key, laundry card or parking stall across the strata spreadsheets and the `mesh` database. |
| `check_email.pl` | Lists the inbox of the strata Gmail account over IMAP. |
| `copy-minutes-to-website.sh` | Fetches the meeting minutes from email and copies them to the website over ssh/scp. |
| `update-welcome-pdf.sh` | Copies the Welcome Brochure PDF to the website with `scp`. |
| `node/` | Node ports of `check_email` and `fob-log-query` (work in progress). |

## Requirements

- `psql` and a route to the `mesh` server on the 123 network (e.g. host `cpbee`,
  or any machine with `postgresql-client`). The database password is not
  stored in the repo: the scripts get it from `foo("mesh")` in
  `~/user_*/Foo_Bar.*` (add it once with `bar mesh <password> mesh` as the
  user; the stored user name is `mesh`).
- Perl with `Modern::Perl`, `DBI`, `DBD::CSV`, `DBD::Pg`, `Net::IMAP::Simple`,
  `Email::MIME` and the local `Foo_Bar` and `Excel2CSV` modules.
- Gmail access uses an **app password**, looked up by `Foo_Bar`.
- Source documents live in `~/OneDrive/!Shared/Strata/docs`, except the Welcome
  Brochure, which is in `!CP+MH/Strata/Strata Documents/Welcome Brochure`.

## Notes

- `*.log`, `*.out` and `tmp/` are git-ignored. Scripts started from cron write
  their logs next to themselves.
- `fob-log-query.pl` and `unit-query.pl` change into `$Bin/../tmp` and
  `$Bin/../docs/tmp`, relative to where the script lives. Check those paths
  still point where you expect now that the scripts are in `bin/`.
- The repo is public. Don't commit resident data (spreadsheets, fob logs) or
  credentials.
