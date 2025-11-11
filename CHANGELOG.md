# Change Logs

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

