require! <[fs express path @plotdb/srcbuild @plotdb/colors lderror body-parser]>
require! <[jsdom dompurify]>
printer = require "../src/index"

if !process.env.APIKEY =>
  console.log "please specify environment variable APIKEY for remote generation"
  process.exit!

{ window } = new jsdom.JSDOM "<!DOCTYPE html>"
purify = dompurify window
remote-printer = new printer server: url: process.env.URL, key: (process.env.APIKEY).trim!
(printer) <- printer.get!then _

lib = fs.realpathSync path.dirname __filename

server = do
  init: (opt={}) ->
    app = express!
    app.use \/, express.static \web/static
    app.use body-parser.json!
    app.post \/api/print/remote, (req, res) ->
      url = req.body.url or \https://info.cern.ch/
      html = req.body.html or (if url => undefined else 'hello world')
      filename = "output.pdf"
      remote-printer.print {url, html}
        .then ({stream}) ->
          res.setHeader \Content-Type, \application/pdf
          res.setHeader \Content-Disposition, "inline; filename=\"#filename\""
          stream.pipe res
        .catch ->
          console.log it
          res.status 500 .send!

    app.post \/api/print/local, (req, res) ->
      url = req.body.url or \https://info.cern.ch/
      html = purify.sanitize req.body.html or ""
      printer.print {url, html}
        .then -> res.send it
        .catch -> res.status 500 .send!

    srcbuild.lsp({ base: "web" })

    console.log "[Server] Express Initialized in #{app.get \env} Mode".green
    server = app.listen opt.port, ->
      delta = if opt.start-time => "( takes #{Date.now! - opt.start-time}ms )" else ''
      console.log "[SERVER] listening on port #{server.address!port} #delta".cyan

server.init {port: 9899}

