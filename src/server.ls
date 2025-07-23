require! <[express jsonwebtoken]>
print = require "./index"

APIKEY = process.env.APIKEY or 'api-key-not-given'
printer = new print!
process.on \SIGINT, -> process.exit!

app = express!
app.get \/ping, (req, res) -> res.send {text: "pong"}
app.post \/pdf, (req, res) ->
  try
    if !(token = req.body.token) => throw new Error! 
    payload = jsonwebtoken.verify token, apikey
    if !(payload.url or payload.html) => throw new Error!
  catch e => res.status 404 .send!
  <- printer.init!then _
  <- printer.print payload{url,html} .then _
  res.send it

port = process.env.PORT or 8080
app.listen port

