class Point
  constructor: (@x, @y) ->

# ===============================

class Key
  @ctrl: 17
  @shift: 16
  @alt: 18
  @space: 32
  @enter: 13

# ===============================

class KeyState
  keys:{}
  codeToKey: [] #maps int -> keyname for reverse lookup
  constructor: ->
    for key of Key then do =>
      @[key] = false
      @codeToKey[Key[key]] = key
    @createBindings()

  createBindings: ->
    setDown = (val) => (ev) =>
      keyname = @codeToKey[ev.keyCode]
      @[keyname] = val if keyname

    document.addEventListener("keydown", setDown(true))
    document.addEventListener("keyup", setDown(false))

# ===============================

class Joystick
  active:false
  start: new Point(0,0)
  now: new Point(0,0)
  sensitivity: new Point(200,1000000)

  constructor: (@canvas) ->
    @g = canvas.getContext('2d')
    @createBindings()

  onActivate: -> # noop unless overriden
  onRelease: -> # noop unless overriden

  dx: (sensitivity) -> (@now.x - @start.x) / (sensitivity || @sensitivity.x)
  dy: (sensitivity) -> (@now.y - @start.y) / (sensitivity || @sensitivity.y)

  clear: -> #noop for now
  draw: ->  #noop for now

  createBindings: ->
    @canvas.onmousedown = (ev) =>
      if ev.button == 0
        @onActivate()
        @active = true
        @start = new Point(ev.pageX, ev.pageY)
      return false # disable text-selection of canvas / other elements

    document.onmouseup = =>
      @active = false
      @onRelease()

    document.onmousemove = (ev) =>
      @now.x = ev.pageX
      @now.y = ev.pageY

# ===============================