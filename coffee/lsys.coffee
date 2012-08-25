window.go = () ->
  control = (name) -> document.getElementById(name)
  value = (name) -> control(name).value
  canvas = document.getElementById('c')
  g = canvas.getContext('2d')

  
  clone = (c) -> {
    x:c.x,
    y:c.y,
    angle:c.angle,
    incAngle:c.incAngle,
    incLength:c.incLength
  }
  context = {
    x:canvas.width/2,
    y:canvas.height/2,
    angle:0,
    incAngle:value("angle"),
    incLength:value("length")
  }


  rules = document.getElementById('rules').value
  rules = rules.split("\n").map (rule) -> rule.split(" : ")

  rule = `{}`
  rule[r] = exp for [r,exp] in rules

  iterations = value("num")

  s = new Date
  start = rule[rules[0][0]]
  stack = []
  expr = start
  expr = _.reduce expr.split(""), ((acc, symbol) ->
    acc + (rule[symbol] || symbol)
  ), "" for i in [1..iterations] 

  control("generated").innerText = (new Date - s)

  window.test = expr

  cos = Math.cos
  sin = Math.sin
  functions = {
    "F": (g) -> 
      #len = context.incLength
      #ang = context.angle #(context.angle / 180) * Math.PI
      #context.x = context.x+cos(ang)*len
      #context.y = context.y+sin(ang)*len
      ##g.lineTo(context.x,context.y)
    "+": () -> context.angle += context.incAngle 
    "-": () -> context.angle -= context.incAngle
    "|": () -> context.angle += 180
    "[": () -> stack.push(clone context)
    "]": () -> context = stack.pop(); g.moveTo(context.x,context.y)
    "!": () -> context.incAngle *= -1
    "(": () -> context.incAngle *= 0.95
    ")": () -> context.incAngle *= 1.05
    "<": () -> context.incLength *= 1.01
    ">": () -> context.incLength *= 0.99
  }


  
  g.globalAlpha=1
  g.fillStyle="#202020"
  g.beginPath()
  g.rect(0,0,1000,1000)
  g.fill()
  g.closePath()
  g.lineWidth = 0.4
  g.strokeStyle="#fff"
  g.globalAlpha=0.4

  
  time = (f) -> (s = new Date; f(); console.log(new Date - s);)
  
  time (f) -> expr.split("")
  console.log(expr.length)

  x = _.map [1..10], (i) -> 
    s = new Date
    #g.beginPath()
    _.each expr, (e) ->
      functions[e] && functions[e](g)
    #g.closePath()
    #g.stroke()
    return new Date() - s

  control("rendered").innerText = (_.reduce x, (x,y) -> x+y)/x.length
