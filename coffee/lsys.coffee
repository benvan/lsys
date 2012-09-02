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

        g.lineTo(context.x,context.y) if len > 0.1 || Math.random() < 0.3
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

    textRules = stringvalue('rules').split("\n").map (r) -> (r.replace(/\ /g, '')).split(':')
    iterations = value("num")

    ruleMap[r] = exp for [r,exp] in textRules

    expr = textRules[0][0]

    elems = []
    expr = _.reduce expr.split(""), ((acc, symbol) ->
      acc + (ruleMap[symbol] || symbol)
    ), "" for i in [1..iterations]
    elems = expr.split("")

    setupControls()


  setupControls = ->
    document.onkeydown = (ev) ->
      window.lsys() if ev.keyCode == 13 and ev.ctrlKey

    canvas.onmousedown = (ev) ->
      client.down = true
      client.context.length = value("length")
      client.context.angle = value("angle")
      client.start.y = ev.clientY
      client.start.x = ev.clientX

    document.onmouseup = -> client.down = false

    document.onmousemove = (ev) ->
      client.now.x = ev.clientX
      client.now.y = ev.clientY
      if (client.down)
        x = (client.now.x - client.start.x) / 20
        y = (client.start.y - client.now.y) / 100
        control("angle").value = x + client.context.angle
        control("length").value = y + client.context.length
        draw() if not isDrawing

#-----------------------------
# helper functions
  log = (x) -> console.log(x)
  control = (name) -> document.getElementById(name)
  value = (name) -> parseFloat(stringvalue(name))
  stringvalue = (name) -> control(name).value
  time = (n,f) -> 
    f = n if n instanceof Function
    s = new Date; f(); (new Date - s)
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
    g.rect(-1,-1,700,700)
    g.fill()
    g.closePath()
    g.lineWidth = 0.7
    g.strokeStyle="#fff"
    g.globalAlpha=0.4
    # ------------------

    t = time ->
      g.moveTo(context.x, context.y)
      _.each elems, (e) ->
        definitions[e](g) if definitions[e] 
      g.stroke()

    control("rendered").innerText = t+"ms"
    control("segments").innerText = elems.length
    isDrawing = false

  init()
  draw()
