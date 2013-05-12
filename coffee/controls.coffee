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
      console.log(keyname)
      @[keyname] = true if keyname
      for key of KeyState then do -> console.log(key)

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

  release: ->
    @active = false

  dx: -> (@now.x - @start.x)/@sensitivity.x
  dy: -> (@now.y - @start.y)/@sensitivity.y

  clear: -> #noop for now
  draw: ->  #noop for now

  createBindings: ->
    @canvas.onmousedown = (ev) =>
      @active = true
      @start = new Point(ev.offsetX, ev.offsetY)
      return false #disable text-selection of canvas / other elements

    document.onmousemove = (ev) =>
      @now.x = ev.offsetX
      @now.y = ev.offsetY

# ===============================