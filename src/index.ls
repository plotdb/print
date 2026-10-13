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
      Promise.resolve!
        .then -> cb lc.obj.page
        .catch (e) ~>
          if (lc.trial++) >= 2 => return Promise.reject e
          console.log "[@plotdb/print] retry (#{lc.trial}): ", (e or '').toString!
          @respawn lc.obj .then -> _!
    @get!
      .then (obj) -> lc.obj = obj
      .then -> _!
      .finally ~> if lc.obj => @free lc.obj

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
    axios.post cfg.url, {token}, {responseType: \stream, timeout: cfg.timeout or 0}
      .then (ret) -> {stream: ret.data}

  print-locally: (payload = {}) -> @exec (page) ~>
    # 逐段計時並記錄慢 / 失敗 / 未完成的請求, 以便追查卡住的原因.
    lc = {t0: Date.now!, lap: [], req: new Map!, slow: [], failed: []}
    lap = (n) -> lc.lap.push "#n #{((Date.now! - lc.t0) / 1000).toFixed(1)}s"
    short = (u = '') -> u.replace(/\?.*/, '').substring(0, 120)
    h =
      request: (r) -> lc.req.set r, Date.now!
      requestfinished: (r) ->
        if !(t = lc.req.get r) => return
        lc.req.delete r
        if (d = Date.now! - t) > 3000 => lc.slow.push "#{d}ms #{short r.url!}"
      requestfailed: (r) ->
        lc.req.delete r
        lc.failed.push "#{(r.failure! or {}).errorText} #{short r.url!}"
    for k,v of h => page.on k, v
    timeout = payload.timeout or 30000
    # 只有頁面本身載入失敗才算錯誤 ( 交給 exec 重試 ); 等網路靜止逾時則照常列印,
    # 避免整頁重試拖到後端的 print token 過期.
    p = if payload.html => page.setContent payload.html, {waitUntil: \domcontentloaded, timeout}
    else if payload.url => page.goto payload.url, {waitUntil: \domcontentloaded, timeout}
    else Promise.reject(new lderror(1015))
    p
      .then -> lap \dom
      .then -> page.waitForNetworkIdle {idleTime: 500, timeout: (payload.idle-timeout or 20000)}
      .catch (e) ->
        if !(e and e.name == \TimeoutError) or !lc.lap.length => return Promise.reject e
        lc.idle-timeout = true
      .then -> lap \idle
      .then -> debounce(payload.debounce or 2000)
      .then ->
        page.evaluate ->
          ps = Array.from(document.images).map (img) ->
            (res, rej) <- new Promise _
            if img.complete => return res!
            img.addEventListener \load, -> res!
            img.addEventListener \error, -> res!
          return Promise.race [Promise.all(ps), new Promise((res) -> setTimeout res, 10000)]
      .then -> lap \img
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
        client.detach!catch ->
        Buffer.from data, \base64
      .then (ret) ->
        lap \pdf
        if !(ret instanceof Buffer) => ret = Buffer.from(ret)
        return {buf: ret}
      .finally ~>
        if @opt.log =>
          pending = Array.from(lc.req.keys!).map (r) -> short r.url!
          console.log "[@plotdb/print] #{lc.lap.join ' / '}#{if lc.idle-timeout => ' (idle timeout)' else ''}"
          if lc.slow.length => console.log "[@plotdb/print] slow requests:\n  " + lc.slow.join('\n  ')
          if lc.failed.length => console.log "[@plotdb/print] failed requests:\n  " + lc.failed.join('\n  ')
          if pending.length => console.log "[@plotdb/print] pending requests:\n  " + pending.join('\n  ')
        for k,v of h => page.off k, v
        # 清空頁面以釋放記憶體; 分頁會被重複使用.
        page.goto \about:blank .catch ->

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
      .then -> if !(obj.page.isClosed!) => obj.page.close!
      .catch -> # failed to close. anyway, just ignore it and create a new page.
      .then -> printer.launch!
      .then (browser) -> browser.newPage!
      .then (page) ~> obj.page = page

  # 可重複呼叫; 分頁只建立一次.
  init: ->
    if @_init => return @_init
    @_init = ctx.prepare!
      .then -> printer.launch!
      .then (browser) ~>
        Promise.all (for i from 0 til @count => browser.newPage!then(-> {busy: false, page: it}))
      .then ~> @pages = it
      .catch (e) ~>
        @_init = null
        Promise.reject e

# 共用的 browser; 斷線 ( 例如 OOM ) 後下次呼叫會重新啟動, 舊分頁由 exec 重試時 respawn 換掉.
printer.launch = ->
  if @_launch => return @_launch
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
  @_launch = ctx.puppeteer.launch {headless: true, args: args}
    .then (browser) ~>
      @browser = browser
      browser.on \disconnected, ~>
        console.log "[@plotdb/print] browser disconnected."
        if @browser == browser => @ <<< {browser: null, _launch: null}
      browser
    .catch (e) ~>
      @_launch = null
      Promise.reject e

module.exports = printer
