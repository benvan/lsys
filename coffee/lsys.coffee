window.lsys = () ->
# fields ----------------------
  definitions =
  client =
  context =
  stack =
  elems =
  textRules =
  ruleMap =
  isDrawing =
  bounding =
  activeSystem =
  iterations = {}
#----------------------

  init = ->
    [cos,sin,pi,min,max] = [Math.cos, Math.sin, Math.PI,Math.min,Math.max]
    len = ang = s = c = 0
    definitions = {
      "F": (g) ->

        len = context.incLength
        ang = ((context.angle%360) / 180) * pi
        s = sin(ang)
        c = cos(ang)
        context.x += c*len
        context.y += s*len

        #bounding.x1 = min(context.x,bounding.x1)
        #bounding.x2 = max(context.x,bounding.x2)
        #bounding.y1 = min(context.y,bounding.y1)
        #bounding.y2 = max(context.y,bounding.y2)

        g.lineTo(context.x,context.y)
      "+": -> context.angle += context.incAngle
      "-": -> context.angle -= context.incAngle
      "|": -> context.angle += 180
      "[": -> stack.push(clone context)
      "]": -> context = stack.pop(); g.moveTo(context.x,context.y)
      "!": -> context.incAngle *= -1
      "(": -> context.incAngle *= 0.95
      ")": -> context.incAngle *= 1.05
      "<": -> context.incLength *= 1.01
      ">": -> context.incLength *= 0.99
    }

    client =
      down:false
      start:
        x:0
        y:0
      now:
        x:0
        y:0
      context:
        angle:0
        length:0

    context =
      x:0
      y:0
      angle:0
      incAngle:0
      incLength:0

    generate()
    setupControls()
    initFromUrl()

  generate = ->
    activeSystem = stringvalue('rules')
    textRules = activeSystem.split("\n").map (r) -> (r.replace(/\ /g, '')).split(':')
    iterations = value("num")

    ruleMap[r] = exp for [r,exp] in textRules

    expr = textRules[0][0]

    elems = []
    expr = _.reduce expr.split(""), ((acc, symbol) ->
      acc + (ruleMap[symbol] || symbol)
    ), "" for i in [1..iterations]
    elems = expr.split("")




  setupControls = ->
    document.onkeydown = (ev) ->
      if ev.keyCode == 13 and ev.ctrlKey
        location.hash = mkurl()
        window.lsys()

    canvas.onmousedown = (ev) ->
      client.down = true
      client.context.length = value("length")
      client.context.angle = value("angle")
      client.start.y = ev.clientY
      client.start.x = ev.clientX
      return false

    document.onmouseup = ->
      client.down = false
      location.hash = mkurl()

    document.onmousemove = (ev) ->
      client.now.x = ev.clientX
      client.now.y = ev.clientY
      if (client.down)
        x = (client.now.x - client.start.x) / 10
        y = (client.start.y - client.now.y) / 100
        control("angle").value = round(x + client.context.angle, 2)
        control("length").value = round(y + client.context.length, 2)
        if not isDrawing
          isDrawing = true
          draw()

    window.onhashchange = initFromUrl


  initFromUrl = ->
    if location.hash != ""
      params = readurl()
      prevNum = control("num").value
      control("num").value = params.it
      control("length").value = params.l
      control("angle").value = params.a
      control("rules").value = decodeURIComponent(params.r)

      generate() if (activeSystem != stringvalue("rules") or prevNum != params.it)
      draw()

#-----------------------------
# helper functions
  log = (x) -> console.log(x)
  control = (name) -> document.getElementById(name)
  value = (name) -> parseFloat(stringvalue(name))
  stringvalue = (name) -> control(name).value
  round = (n,d) ->
    pow = Math.pow(10,d)
    Math.round(n*pow) / pow
  time = (n,f) -> 
    f = n if n instanceof Function
    s = new Date; f(); (new Date - s)
  mkurl = ->
    params =
      it: value("num")
      l:  value("length")
      a:  value("angle")
      r:  encodeURIComponent(stringvalue("rules"))

    url = _.reduce(params,(acc,v,k) ->
      acc+k+"="+v+"&"
    ,"#")
    return url.substring(0,url.length-1)

  readurl = ->
    params = {}
    _.each(location.hash.substring(1).split("&").map( (x) -> x.split("=")), ([k,v]) ->
      params[k] = v
    )
    return params


#-----------------------------

  canvas = document.getElementById('c')
  g = canvas.getContext('2d')
  
  # expanded (explicit) for efficiency
  clone = (c) -> {
    x:c.x,
    y:c.y,
    angle:c.angle,
    incAngle:c.incAngle,
    incLength:c.incLength
  }


  # render method ----------------
  draw = () ->
    isDrawing = true
    stack = []
    bounding =
      x1:Infinity
      x2:0
      y1:Infinity
      y2:0
    context = {
      x:canvas.width/2,
      y:canvas.height/2,
      angle:-90,
      incAngle:value("angle"),
      incLength:value("length")
    }

    # ------------------
    g.globalAlpha=1
    g.fillStyle="#202020"
    g.beginPath()
    g.clearRect(0,0,700,700)
    g.fill()
    g.closePath()
    g.lineWidth = 0.2
    g.strokeStyle="#fff"
    g.globalAlpha=0.2

    #g.globalCompositeOperation = "source-over"
    # ------------------

    t = time ->
      g.moveTo(context.x, context.y)
      _.each elems, (e) ->
        definitions[e](g) if definitions[e]
      g.stroke()


    control("rendered").innerHTML = t+"ms"
    control("segments").innerHTML = elems.length
    isDrawing = false

  init()
  draw()
