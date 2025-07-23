ldld = new ldloader className: 'ldld full'
get-pdf = ({method = \local, type = \html} = {}) ->
  console.log "prepareing pdf ... "
  ldld.on!
  json = if type == \html => html: "<h1>Printed</h1><p> with HTML as payload </p>" 
  else link: "https://info.cern.ch/"
  ld$.fetch "/api/print/#mthod", {method: \POST}, {json}
    .finally -> ldld.off!
    .then (r) -> r.blob!
    .then (blob) ->
      console.log 'returned blob:', blob
      ldfile.download {blob, name: "result.pdf"}

view = new ldview do
  root: document.body
  action: click: "print": ({node}) -> get-pdf node.dataset
