window.lsys = () ->
# fields ----------------------
  definitions =
  client =
  context =
  stack =
  textRules =
  ruleMap =
  isDrawing = 
  iterations = {}
#----------------------
  
  init = ->
    [cos,sin,pi] = [Math.cos, Math.sin, Math.PI]
    definitions = {
      "F": (g) ->
        len = context.incLength
        ang = ((context.angle%360) / 180) * pi
        context.x = context.x+cos(ang)*len
        context.y = context.y+sin(ang)*len
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

    textRules = stringvalue('rules').split("\n").map (r) -> (r.replace(/\ /g, '')).split(':')
    iterations = value("num")

    ruleMap[r] = exp for [r,exp] in textRules

    setupControls()

  
  setupControls = ->
    document.onkeydown = (ev) ->
      window.lsys.run if ev.keyCode == 13 and ev.ctrlKey

    canvas.onmousedown = (ev) ->
      client.down = true
      client.context.length = value("length")
      client.context.angle = value("angle")
      client.start.y = ev.clientY
      client.start.x = ev.clientX

    canvas.onmouseup = -> client.down = false
    
    canvas.onmousemove = (ev) ->
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
    context = {
      x:canvas.width/2,
      y:canvas.height,
      angle:-90,
      incAngle:value("angle"),
      incLength:value("length")
    }
    start = textRules[0][0]
    expr = start

    # ------------------
    g.globalAlpha=1
    g.fillStyle="#202020"
    g.beginPath()
    g.rect(-1,-1,1000,1000)
    g.closePath()
    g.fill()
    g.lineWidth = 0.7
    g.strokeStyle="#fff"
    g.globalAlpha=0.4
    # ------------------

    elems = []
    t = time ->
      expr = _.reduce expr.split(""), ((acc, symbol) ->
        acc + (ruleMap[symbol] || symbol)
      ), "" for i in [1..iterations]
      elems = expr.split("")

      g.moveTo(context.x, context.y)
      _.each elems, (e) ->
        definitions[e] && definitions[e](g)
      g.stroke()

    control("rendered").innerText = t+"ms"
    control("segments").innerText = elems.length
    isDrawing = false

  init()
  draw()
