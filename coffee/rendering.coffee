class RenderingContext
  initialised:false
  state:null
  bounding:null
  stack:[]
  constructor: (@container) ->

  reset: (system) =>
    @initialised = true
    @state =
      x:              (@container.clientWidth/2)+system.offsets.x
      y:              (@container.clientHeight/2)+system.offsets.y
      orientation:    -90 + system.offsets.rot
      stepAngle:      system.params.angle.value
      stepSize:       system.params.size.value
      color:          0
    @bounding = new Bounding
    @stack = []

  # receive gs from renderer. These will change on system change
  prepare: (gs) => @gs = gs; @g = gs[0];

#================================================================

class Bounding
  x1: Infinity
  y1: Infinity
  x2: -Infinity
  y2: -Infinity
  width: => (@x2-@x1)
  height: => (@y2-@y1)
  constrain: (x,y) ->
    @x1 = Math.max(@x1, 0)
    @y1 = Math.max(@y1, 0)
    @x2 = Math.min(@x2, x)
    @y2 = Math.min(@y2, y)

#================================================================

getG = (c) -> c.getContext('2d')
getColors = (system) -> ["#ffffff","#0044DD","#00DD44","#DD4400"]

class Renderer
  context:null
  g:null
  stack:[]
  isDrawing:false
  constructor: (@container) ->
    @context = new RenderingContext(@container)

  prepare: (system) =>
    colors = getColors(system)
    # ensures numColors canvases available
    diff = colors.length - @container.children.length
    while (diff-- > 0)
      @container.appendChild(document.createElement("canvas"))
    canvii = [].slice.apply(@container.children)
    Util.enhanceAndStretchCanviiInContainer(@container)
    gs = canvii.map(getG)
    colors.forEach (c,i) -> gs[i].strokeStyle = c
    @context.prepare(gs)

  clearCanvas: =>
    if (@context.initialised)
      b = @context.bounding
      p = padding = 5
      b.constrain(@container.clientWidth, @container.clientHeight)
      @context.gs.forEach (g) -> g.clearRect(b.x1-p, b.y1-p, b.width()+2*p, b.height()+2*p)

  reset: (system) =>
    @clearCanvas()
    @context.reset(system)

  render: (elems, system) =>
    @isDrawing = true
    start = new Date

    this.reset(system)

    @context.gs.forEach (g,i) =>
      g.lineWidth = 0.218
      g.beginPath()
      g.moveTo(@context.state.x, @context.state.y)

    #initialise lower-bounds
    [s,b] = [@context.state, @context.bounding]
    [b.x2,b.y2] = [s.x, s.y]

    #draw
    _.each elems, (e) =>
      @definitions[e](@context.state, system.params, @context, e)

    @context.gs.forEach (g) -> g.stroke()


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
      x:              c.x
      y:              c.y
      orientation:    c.orientation
      stepAngle:      c.stepAngle
      stepSize:       c.stepSize
      color:          c.color
    }
    return {
    "F": (state, params, context) ->

      ang = ((state.orientation%360) / 180) * pi #todo - stop storing degrees?!
      state.x += cos(ang)*state.stepSize
      state.y += sin(ang)*state.stepSize

      bounding = context.bounding

      if (state.x < bounding.x1)
        bounding.x1 = state.x
      else if (state.x > bounding.x2)
        bounding.x2 = state.x

      if (state.y < bounding.y1)
        bounding.y1 = state.y
      else if (state.y > bounding.y2)
        bounding.y2 = state.y

      context.g.lineTo(state.x,state.y)

    "+": (state) -> state.orientation += state.stepAngle
    "-": (state) -> state.orientation -= state.stepAngle
    "|": (state) -> state.orientation += 180
    #todo: push stack changes into RenderingContext class
    "[": (state, params, context) -> context.stack.push(cloneState state)
    "]": (state, params, context) -> context.state = state = context.stack.pop(); context.g = context.gs[state.color]; context.g.moveTo(state.x,state.y)
    "!": (state) -> state.stepAngle *= -1
    "(": (state, params) -> state.stepAngle *= (1 - params.angle.growth)
    ")": (state, params) -> state.stepAngle *= (1 + params.angle.growth)
    "<": (state, params) -> state.stepSize *= (1 + params.size.growth)
    ">": (state, params) -> state.stepSize *= (1 - params.size.growth)
    "0": (state, params, context, a) -> state.color = a; if (context.g != context.gs[0]) then ( context.g = context.gs[0]; context.g.moveTo(state.x,state.y))
    "1": (state, params, context, a) -> state.color = a; if (context.g != context.gs[1]) then ( context.g = context.gs[1]; context.g.moveTo(state.x,state.y))
    "2": (state, params, context, a) -> state.color = a; if (context.g != context.gs[2]) then ( context.g = context.gs[2]; context.g.moveTo(state.x,state.y))
    "3": (state, params, context, a) -> state.color = a; if (context.g != context.gs[3]) then ( context.g = context.gs[3]; context.g.moveTo(state.x,state.y))
    }
  )()
