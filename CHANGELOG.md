# Change Logs

## v0.2.5

 - server: send PDF with chunked transfer encoding so responses over Cloud Run's 32MiB limit ( for responses with Content-Length ) can be delivered

## v0.2.4

 - fix memory leak: `init` now only creates pages once instead of every call ( server calls it per request )
 - relaunch browser after it disconnects ( e.g., OOM ), and fix `respawn` closing an undefined `page`
 - wait for `domcontentloaded` then network idle ( capped at `idle-timeout`, default 20s ) instead of `networkidle0`,
   so a hanging request no longer fails the whole job and triggers reloads
 - cap image waiting to 10s, reduce retries from 6 to 2, reset page to `about:blank` after printing
 - server: respond 500 on failure instead of leaving the request hanging; log timings and slow / failed / pending requests
 - support `timeout` option in `server` config for remote printing

## v0.2.3

 - tweak image promises to prevent broken images from blocking page loading
 - use Chrome DevTools Protocl (CDP) for PDF to prevent ReadableStream exception in older Nodejs by puppeteer


## v0.2.2

 - fix bug: print server return incorrect field from printed result.


## v0.2.1

 - limit release scope to dist files only


## v0.2.0

 - support PDF generation through remote api endpoint 
 - support running printer as a print server
 - support running server via docker
 - (breaking change) change returned value from print to `{buffer}` instead of `buffer` to align with remote api spec and make it foolproof about the returned value.


## v0.0.5

 - (from 0.1.2) ensure image loaded before printing


## v0.1.2

 - ensure image loaded before printing


## v0.1.1

 - Merge feature update from version/0.0 branch


## v0.1.0

Breaking Changes: upgrade to node >18 will be required for puppeteer > 23.11.1

 - make sure printer returns Buffer 
 - upgrade puppeteer
 - fix demo server bug


## v0.0.4

 - skip 0.0.3 due to mistake during publish
 - add `debounce` option in print for a custom delay between page ready / print


## v0.0.2

 - fix bug: `init` should wait until browser is ready.
 - npm audit fix to fix vulnerabilities in dependencies.


## v0.0.1

 - init release

