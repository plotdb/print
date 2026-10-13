require! <[express jsonwebtoken]>
print = require "./index"

APIKEY = (process.env.APIKEY or 'api-key-not-given').trim!
printer = new print {log: true}
process.on \SIGINT, -> process.exit!

app = express!
app.use express.json!
app.get \/ping, (req, res) -> res.send {text: "pong"}
app.post \/pdf, (req, res) ->
  try
    if !(token = req.body.token) => throw new Error! 
    payload = jsonwebtoken.verify token, APIKEY
    if !(payload.url or payload.html) => throw new Error!
  catch e =>
    console.log "[payload verify failed] ", e.toString!
    return res.status 404 .send!
  log-text = if payload.url => "url: #{payload.url}"
  else if payload.html => "html: #{(payload.html + '').length}bytes"
  else "(payload: no content)"
  tag = "[#{payload.timestamp or 'no-timestamp'}]"
  console.log "#tag " + log-text
  t0 = Date.now!
  printer.init!
    .then -> printer.print payload{url, html}
    .then ({buf}) ->
      console.log "#tag done in #{((Date.now! - t0) / 1000).toFixed(1)}s, #{buf.length} bytes"
      res.setHeader \Content-Type, \application/octet-stream
      res.end buf
    .catch (e) ->
      console.log "#tag [print failed] ", (e or '').toString!
      if !res.headersSent => res.status 500 .send!

port = process.env.PORT or 8080
app.listen port

