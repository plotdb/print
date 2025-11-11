require! <[axios lderror @loadingio/debounce.js jsonwebtoken]>

ctx = prepare: ->
  <~ Promise.resolve!then _
  if @inited => return
  try
    <[fs puppeteer tmp easy-pdf-merge]>.map ~> @[it] = require it
  catch e
    console.warn "[@plotdb/print] Dependencies import failed. Peer Dependencies ( puppeteer, tmp, easy-pdf-merge ) are required when using @plotdb/print in local mode. Please install them via npm"
    return lderror.reject 1022
  @inited = true

tmpfn = ->
  (res, rej) <- new Promise _
  ctx.tmp.file (err, path, fd, cb) ->
    if err => return rej err
    res {fn: path, clean: cb}

printer = (opt = {}) ->
  @opt = opt
  @count = ((opt.count or 4) <? 20)
  @queue = []
  @

printer.get = ->
  <~ Promise.resolve!then _
  if @_printer => return @_printer
  @_printer = new printer {count: 15}
  <~ @_printer.init!then _
  @_printer

printer.prototype = Object.create(Object.prototype) <<< do
  exec: (cb) ->
    lc = {trial: 0}
    _ = ~>
      @get!
        .then (obj) -> lc.obj = obj
        .then -> cb(lc.obj.page)
        .then -> lc.ret = it
        .catch ~>
          if (lc.trial++) > 5 => return Promise.reject new lderror(0)
          @respawn lc.obj .then -> _!
        .then ~> @free lc.obj
        .then -> return lc.ret
    _!
  merge: (payload = {}) ->
    Promise.resolve!
      .then ~>
        if !payload.html => return null
        @print {html: payload.html} .then (buf) ->
          tmpfn!then ({fn}) ->
            (res, rej) <- new Promise _
            (e) <- ctx.fs.write-file fn, buf, _
            if e => return rej new Error(e)
            res fn
      .then (form-fn) ->
        if !payload.files or payload.files.length < 1 or (payload.files.length == 1 and !form-fn) =>
          return Promise.reject(new lderror(400))
        (res, rej) <- new Promise _
        (e) <- ctx.easy-pdf-merge ((if form-fn => [form-fn] else []) ++ payload.files), payload.outfile, _
        if e => return rej e
        res payload.outfile

  print: (payload = {}) ->
    return if !@opt.server => @print-locally payload else @print-remotely payload

  print-remotely: ({url, html}) ->
    payload = {url, html, timestamp: Date.now!}
    if !((cfg = @opt.server or {}) and cfg.key and cfg.url) => return lderror.reject 1015
    token = jsonwebtoken.sign payload, cfg.key
    axios.post cfg.url, {token}, {responseType: \stream}
      .then (ret) -> {stream: ret.data}

  print-locally: (payload = {}) -> @exec (page) ->
    p = if payload.html => page.setContent payload.html, {waitUntil: "networkidle0"}
    else if payload.url => page.goto payload.url, {waitUntil: "networkidle0"}
    else Promise.reject(new lderror(1015))
    # note: if this Promise rejects with exception, `exec` will retry several times.
    # be sure to check if anything wrong in your code if download keep on failing.
    p
      .then -> debounce(payload.debounce or 2000)
      .then ->
        page.evaluate ->
          ps = Array.from(document.images).map (img) ->
            (res, rej) <- new Promise _
            if img.complete => return res!
            img.addEventListener \load, -> res!
            img.addEventListener \error, -> res!
          return Promise.all ps
      .then ->
        # 1. with puppeteer API: use web stream. requires newer NodeJS (> 18)
        # it throws exception (ReadableStream is not a constructor) with older nodejs (v16):
        #page.pdf format: \A5
        # 2. with Chrome DevTools Protocol (CDP), by pass puppeteer directly.
        (client) <- page.target!createCDPSession!then _
        opt =
          printBackground: true
          paperWidth: 5.8  # A5 width (inch)
          paperHeight: 8.3 # A5 height (inch)
        ({data}) <- client.send 'Page.printToPDF', opt .then _
        Buffer.from data, \base64
      .then (ret) ->
        if !(ret instanceof Buffer) => ret = Buffer.from(ret)
        return {buf: ret}

  get: -> new Promise (res, rej) ~>
    for i from 0 til @pages.length =>
      if !@pages[i].busy =>
        @pages[i].busy = true
        return res @pages[i]
    @queue.push {res, rej}

  free: (obj) ->
    if @queue.length =>
      ret = @queue.splice(0, 1).0
      ret.res obj
    else
      obj.busy = false

  respawn: (obj) ->
    Promise.resolve!
      .then -> if !(obj.page.isClosed!) => page.close!
      .catch -> # failed to close. anyway, just ignore it and create a new page.
      .then -> printer.browser.newPage!
      .then (page) ~> obj.page = page

  init: ->
    ctx.prepare!
      .then ->
        if printer.browser => return Promise.resolve(that)
        args = [
          # usually not available on containers
          "--disable-gpu"
          # to avoid issues with Docker’s default low shared memory space of 64MB. write to /tmp instead
          "--disable-dev-shm-usage"
          # disable sandbox when using ROOT user (not recommended)
          "--disable-setuid-sandbox", 
          "--no-sandbox",
          # FATAL:zygote_main_linux.cc(162)] Check failed: sandbox::ThreadHelpers::IsSingleThreaded()
          "--single-process"
        ] 
        return ctx.puppeteer.launch({headless: true, args: args})
      .then (browser) ~>
        printer.browser = browser
        Promise.all (for i from 0 til @count => browser.newPage!then(-> {busy: false, page: it}))
      .then ~> @pages = it

module.exports = printer
