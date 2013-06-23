class Util
  @log:(x) -> console.log(x)
  @control:(name) -> document.getElementById(name)
  @value: (name) => parseFloat(Util.stringvalue(name))
  @stringvalue: (name) -> Util.control(name).value
  @clone:(x) -> JSON.parse(JSON.stringify(x))
  @map: (obj, fn) ->
    result = {}
    for key of obj then do ->
      result[key] = fn(obj[key], key)
    return result
  @merge: (a,b) -> $.extend(true, a,b)
  @round: (n,d) ->
    pow = Math.pow(10,d)
    Math.round(n*pow) / pow
  @time: (n,f) ->
    f = n if n instanceof Function
    s = new Date; f(); (new Date - s)
  @openDataUrl: (data) ->
    a = document.createElement("a")
    a.href = data
    a.download="lsys/"+$("#systemName").text().replace(/[\ \/]/g,"_")
    evt = document.createEvent("MouseEvents")
    evt.initMouseEvent("click", true, true,window,0,0,0,0,0,true,false,false,false,0,null)
    a.dispatchEvent(evt)
