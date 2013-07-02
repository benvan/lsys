class Point
  constructor: (@x, @y) ->

# ===============================

class Key
  @ctrl: 17
  @meta: 91
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
    document.addEventListener("mousedown", (evt) =>
      for key of Key then do =>
        pressed = evt[key+"Key"]
        @[key] = pressed if pressed?
    )

# ===============================

class Joystick
  active:false
  start: new Point(0,0)
  now: new Point(0,0)

  constructor: (@canvas) ->
    @g = canvas.getContext('2d')
    @createBindings()

  onActivate: -> # noop unless overriden
  onRelease: -> # noop unless overriden

  dx: (sensitivity) -> (@now.x - @start.x) / if (sensitivity) then Math.pow(10,sensitivity) else 1
  dy: (sensitivity) -> (@now.y - @start.y) / if (sensitivity) then Math.pow(10,sensitivity) else 1

  clear: -> #noop for now
  draw: ->  #noop for now

  center: ->
    @start.x = @now.x; @start.y = @now.y

  createBindings: ->
    @canvas.onmousedown = (ev) =>
      if ev.button == 0
        @constrained = ev.shiftKey
        @onActivate()
        @active = true
        @start = new Point(ev.pageX, ev.pageY)

    document.onmouseup = =>
      wasActive = @active
      @active = false
      @onRelease() if wasActive

    document.onmousemove = (ev) =>
      @now.x = ev.pageX
      @now.y = ev.pageY

    document.addEventListener("keydown", () =>
      if (@active)
        @center()
        @onActivate()
    )

# ===============================

# ui binding for a single system variable
class Control
  constructor: (@controlkey) ->
  tpl: -> "you need to override this"
  create: (container) ->
    @el = $(@tpl())
    $(container).append(@el)
    return @el

  getInput: (param) -> @el.find("[data-param=#{param}]")
  getVal: (param) -> parseFloat(@getInput(param).val())
  setVal: (param, value) ->
    input = @getInput(param)
    if (parseFloat(input.val()) != value) then input.val(value)

  toJson: -> return @update({})

  sync: (setting) ->
    _.each(setting, (v,k) => @setVal(k, v))
    return setting

  update: (setting) ->
    _.each(@el.find("[data-param]"), (el) =>
      key = $(el).data("param")
      setting[key] = @getVal(key)
    )
    return setting

class OffsetControl extends Control
  tpl: -> """
          <ul class="control-row">
          <li><input data-param="x" type="text"></li><!--
          --><li><input data-param="y" type="text"></li><!--
          --><li><input data-param="rot" type="text"></li>
          </ul>
          """

class ParamControl extends Control
  tpl: -> """
          <ul class="control-row">
          <li class="label">#{@controlkey}</li><!--
          --><li><input type="text" type="text" data-param="value"></li><!--
          --><li><input type="text" type="text" data-param="growth"></li>
          </ul>
          """
  toJson: ->
    dummy = new Param(@controlkey, 0 , 0)
    return @update(dummy).toJson()

class SensitivityControl extends ParamControl
  toJson: ->
    dummy = new Sensitivity(@controlkey, 0, 0)
    return @update(dummy).toJson()

# container class for all system variables
class Controls
  constructor: (params, ControlType) ->
    @controls = Util.map(params, (p,k) -> new ControlType(k))

  create: (container) ->
    _.each(@controls, (c) -> c.create(container) )

  sync: (params) ->
    Util.map(params, (p) => @controls[p.name].sync(p) )

  toJson: -> Util.map(@controls, (c) -> c.toJson())