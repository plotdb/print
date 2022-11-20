ldld = new ldloader className: 'ldld full'
view = new ldview do
  root: document.body
  action: click: print: ->
    console.log "prepareing pdf ... "
    ldld.on!
    json = html: "<h1>hello world</h1><p> ok </p>"
    ld$.fetch "/api/print", {method: \POST}, {json}
      .finally -> ldld.off!
      .then (r) -> r.blob!
      .then (blob) ->
        console.log 'returned blob:', blob
        ldfile.download {blob, name: "result.pdf"}
