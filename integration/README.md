# rustdesk-api Web Client V1 integration source

`resources-web-js/` is the exact source-and-lockfile snapshot used to build the
JavaScript integration currently served from `resources/web/js/`. It contains
the API configuration, address-book/share handling, temporary-password handling,
WebSocket scheme adaptation, TypeScript sources, generated protocol bindings,
and Vite build configuration.

It is an AGPL-covered modification of the RustDesk Web Client source in the
fixed `../rustdesk-source-*.tar` archive. The complete GNU AGPL v3 text and
original copyright declarations are preserved in `../LICENCE` and that full
source archive.

When this repository is checked out as the `webclient-v1` submodule of
`rustdesk-api`, `../verify-source.sh` also compares this directory with the
API repository's `resources/web/js/`. This prevents the disclosed integration
source from silently drifting from the shipped runtime.
