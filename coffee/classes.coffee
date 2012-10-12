window.lsys = {}

class lsys.Client
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

class lsys.Bounding
  x1: Infinity
  y1: Infinity
  x2: -Infinity
  y2: -Infinity
  width: => (@x2-@x1)
  height: => (@y2-@y1)

class window.lsys.LSystem
  constructor: (@iterations, @size, @angle, @rules, @name) ->
  elements: =>
    if not @generatedElements
      @generate()
    return @generatedElements

  generate: =>
    textRules = @rules.split("\n").map (r) -> (r.replace(/\ /g, '')).split(':')

    ruleMap = {}
    ruleMap[r] = exp for [r,exp] in textRules

    expr = textRules[0][0]

    expr = _.reduce expr.split(""), ((acc, symbol) ->
      acc + (ruleMap[symbol] || symbol)
    ), "" for i in [1..@iterations]

    @generatedElements = expr.split("").filter((e) -> true if (lsys.renderer.definitions[e]))

  merge: (system) =>
    @angle = system.angle
    @size = system.size
    @angle = system.angle
    if (!this.isIsomorphicTo(system))
      @rules = system.rules
      @iterations = system.iterations
      @generate()

  toUrl: =>
    params =
      it: @iterations
      l:  @size
      a:  @angle
      r:  encodeURIComponent(@rules)

    url = _.reduce(params,(acc,v,k) ->
      acc+k+"="+v+"&"
    ,"#")

    return url.substring(0,url.length-1)

  @fromUrl: ->
    return null if location.hash == ""

    params = {}
    _.each(location.hash.substring(1).split("&").map( (x) -> x.split("=")), ([k,v]) ->
      params[k] = v
    )

    return new LSystem(
      parseFloat(params.it)
      ,parseFloat(params.l)
      ,parseFloat(params.a)
      ,decodeURIComponent(params.r)
    )

  isIsomorphicTo: (system) => @rules == system.rules and @iterations == system.iterations

class window.lsys.RenderingContext
  constructor: (@canvas) ->
  reset: (system) =>
    @initialised = true
    @state =
      x:@canvas.width/2,
      y:@canvas.height/2,
      angle:-90,
      incAngle:system.angle
      incLength:system.size
    @bounding = new lsys.Bounding
    @stack = []


class window.lsys.Renderer
  isDrawing:false
  context:undefined
  stack:[]
  g: undefined #canvas context

  constructor: (@canvas) ->
    @g = canvas.getContext("2d")
    @context = new lsys.RenderingContext(@canvas)

  clearCanvas: =>
    if (@context.initialised)
      b = @context.bounding
      p = padding = 5
      @g.clearRect(b.x1-p, b.y1-p, b.width()+2*p, b.height()+2*p)

  reset: (system) =>
    this.clearCanvas()
    @context.reset(system)

  render: (system) =>
    @isDrawing = true
    start = new Date

    this.reset(system)

    @g.lineWidth = 0.4
    @g.strokeStyle="rgba(255,255,255,0.4)"
#    @g.globalAlpha=0.4

    @g.beginPath()
    @g.moveTo(@context.state.x, @context.state.y)

    #initialise lower-bounds
    [s,b] = [@context.state, @context.bounding]
    [b.x2,b.y2] = [s.x, s.y]

    #draw
    _.each system.elements(), (e) =>
      @definitions[e](@context.state, @g, @context) if @definitions[e]

    @g.stroke()
    @g.closePath()

    @isDrawing = false
    return (new Date - start)

  #this really *really* doesn't belong here.. but it requires a hell of a lot more
  #dereferences if I put it anywhere else. Considering it's looked up on the order
  #of hundreds of thousands of times, I'm leaving it here for the time being...
  definitions: (() ->
    [cos,sin,pi,min,max] = [Math.cos, Math.sin, Math.PI,Math.min,Math.max]
    len = ang = s = c = 0
    # expanded (explicit) for efficiency
    cloneState = (c) -> {
    x:c.x,
    y:c.y,
    angle:c.angle,
    incAngle:c.incAngle,
    incLength:c.incLength
    }
    return {
    "F": (state, g, context) ->

      len = state.incLength
      ang = ((state.angle%360) / 180) * pi
      s = sin(ang)
      c = cos(ang)
      state.x += c*len
      state.y += s*len

      bounding = context.bounding

      if (state.x < bounding.x1)
        bounding.x1 = state.x
      else if (state.x > bounding.x2)
        bounding.x2 = state.x

      if (state.y < bounding.y1)
        bounding.y1 = state.y
      else if (state.y > bounding.y2)
        bounding.y2 = state.y

      g.lineTo(state.x,state.y)

    "+": (state) -> state.angle += state.incAngle
    "-": (state) -> state.angle -= state.incAngle
    "|": (state) -> state.angle += 180
    #todo: push stack changes into RenderingContext class
    "[": (state,g, context) -> context.stack.push(cloneState state)
    "]": (state,g, context) -> context.state = state= context.stack.pop(); g.moveTo(state.x,state.y)
    "!": (state) -> state.incAngle *= -1
    "(": (state) -> state.incAngle *= 0.95
    ")": (state) -> state.incAngle *= 1.05
    "<": (state) -> state.incLength *= 1.01
    ">": (state) -> state.incLength *= 0.99
    }
  )()