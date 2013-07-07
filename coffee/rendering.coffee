class RenderingContext
  initialised:false
  state:null
  bounding:null
  stack:[]
  constructor: (@canvas) ->

  reset: (system) =>
    @initialised = true
    @state =
      x:              (@canvas.width/2)+system.offsets.x
      y:              (@canvas.height/2)+system.offsets.y
      orientation:    -90 + system.offsets.rot
      stepAngle:      system.params.angle.value
      stepSize:       system.params.size.value
    @bounding = new Bounding
    @stack = []

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

class Renderer
  context:null
  g:null
  stack:[]
  isDrawing:false
  constructor: (@canvas) ->
    @context = new RenderingContext(canvas)
    @g = canvas.getContext("2d")

  clearCanvas: =>
    if (@context.initialised)
      b = @context.bounding
      p = padding = 5
      b.constrain(@canvas.width, @canvas.height)
      @g.clearRect(b.x1-p, b.y1-p, b.width()+2*p, b.height()+2*p)

  reset: (system) =>
    @clearCanvas()
    @context.reset(system)

  render: (elems, system) =>
    @isDrawing = true
    start = new Date

    this.reset(system)

    @g.lineWidth = 0.3
    @g.strokeStyle="rgba(255,255,255,0.4)"
    #    @g.globalAlpha=0.4

    @g.beginPath()
    @g.moveTo(@context.state.x, @context.state.y)

    #initialise lower-bounds
    [s,b] = [@context.state, @context.bounding]
    [b.x2,b.y2] = [s.x, s.y]

    #draw
    _.each elems, (e) =>
      @definitions[e](@context.state, system.params, @g, @context)

    @g.stroke()


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
    }
    return {
    "F": (state, params, g, context) ->

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

      g.lineTo(state.x,state.y)

    "+": (state) -> state.orientation += state.stepAngle
    "-": (state) -> state.orientation -= state.stepAngle
    "|": (state) -> state.orientation += 180
    #todo: push stack changes into RenderingContext class
    "[": (state, params, g, context) -> context.stack.push(cloneState state)
    "]": (state, params, g, context) -> context.state = state = context.stack.pop(); g.moveTo(state.x,state.y)
    "!": (state) -> state.stepAngle *= -1
    "(": (state, params) -> state.stepAngle *= (1 - params.angle.growth)
    ")": (state, params) -> state.stepAngle *= (1 + params.angle.growth)
    "<": (state, params) -> state.stepSize *= (1 + params.size.growth)
    ">": (state, params) -> state.stepSize *= (1 - params.size.growth)
    }
  )()