class Util
  @log:(x) -> console.log(x)
  @control: (name) ->
    document.getElementById(name) || document.getElementsByClassName(name)
  @value: (name) => parseFloat(Util.stringvalue(name))
  @stringvalue: (name) -> Util.control(name).value
  @arrayvalue: (name) -> Util.mapArray(Util.control(name), (el) -> el.value)
  @clone:(x) -> JSON.parse(JSON.stringify(x))
  @toObj:(kvPairs) ->
    obj = {}
    obj[k] = v for [k,v] in kvPairs
    return obj
  @map: (obj, fn) ->
    result = {}
    for own key of obj then do ->
      result[key] = fn(obj[key], key)
    return result
  @mapArray: (obj, fn) ->
    result = []
    for own key of obj then do ->
      result.push(fn(obj[key], key))
    return result
  @merge: (a,b,c) -> $.extend(true, a,b,c)
  @round: (n,d) ->
    pow = Math.pow(10,d)
    Math.round(n*pow) / pow
  @time: (n,f) ->
    f = n if n instanceof Function
    s = new Date; f(); (new Date - s)
  @openDataUrl: (data, filename) ->
    a = document.createElement("a")
    a.href = data
    a.download=filename
    evt = new MouseEvent('click', { view: window })
    a.dispatchEvent(evt)

  # thanks Brian Nickel http://stackoverflow.com/questions/11163344/update-non-retina-canvas-app-to-retina-display
  @enhanceCanvas = (canvas, container) ->
    context = canvas.getContext('2d')
    ratio = window.devicePixelRatio || 1
    width = canvas.width = $(container).width()
    height = canvas.height = $(container).height()

    if (ratio > 1)
      canvas.width = width * ratio
      canvas.height = height * ratio
      canvas.style.width = width + "px"
      canvas.style.height = height + "px"
      context.scale(ratio,ratio)

  @enhanceAndStretchCanviiInContainer = (container) ->
    $(container).find('canvas').each(() ->
        Util.enhanceCanvas($(this).get(0), container);
    );
