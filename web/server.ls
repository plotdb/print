require! <[fs express path @plotdb/srcbuild @plotdb/colors lderror body-parser]>
require! <[jsdom dompurify]>
printer = require "../src/index"

{ window } = new jsdom.JSDOM "<!DOCTYPE html>"
purify = dompurify window
(printer) <- printer.get!then _

lib = fs.realpathSync path.dirname __filename

server = do
  init: (opt={}) ->
    app = express!
    app.use \/, express.static \web/static
    app.use body-parser.json!
    app.post \/api/print, (req, res) ->
      lc = {}
      html = purify.sanitize req.body.html or ""
      printer.print {html: html}
        .then -> res.send it

    srcbuild.lsp({ base: "web" })

    console.log "[Server] Express Initialized in #{app.get \env} Mode".green
    server = app.listen opt.port, ->
      delta = if opt.start-time => "( takes #{Date.now! - opt.start-time}ms )" else ''
      console.log "[SERVER] listening on port #{server.address!port} #delta".cyan

server.init {port: 9899}

