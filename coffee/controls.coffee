class Point
  constructor: (@x, @y) ->

# ===============================

class Controls
  tpl: (paramName) -> """
          <table><tr>
            <td><div data-control="joystick"</td>
            <td>
              <div class="jostick-inputs-label">#{paramName}</div>
              <input data-control="y" type="text" style="width:100px;"/>
              <input data-control="x" type="text" style="width:100px;"/>
            </td>
          </tr></table>
          """

  _makeJStick: (paramName, mode, flipped = false) ->
    manager = @manager
    control = $(@tpl(paramName))
    $(@container).append(control)
    jstick = new JStickUI(
      container: control.find("[data-control=joystick]")[0]
      mode: mode
      inputs:
        x: control.find("[data-control=x]")[0]
        y: control.find("[data-control=y]")[0]
      getData: ->
        param = manager.getCurrentSystem().params[paramName]
        sensitivity = manager.getCurrentSystem().sensitivities[paramName]
        [x,y] = if not flipped then ['value', 'growth'] else ['growth', 'value']
        return {
          x: param[x]
          y: param[y]
          xSensitivity: sensitivity[x]
          ySensitivity: sensitivity[y]
        }
      setData: (data) ->
        param = manager.getCurrentSystem().params[paramName]
        sensitivity = manager.getCurrentSystem().sensitivities[paramName]
        [x,y] = if not flipped then ['value', 'growth'] else ['growth', 'value']
        param[x] = data.x
        param[y] = data.y
        sensitivity[x] = data.xSensitivity
        sensitivity[y] = data.ySensitivity
    )
  constructor: (@container, @manager) ->
    @angleStick = @_makeJStick('angle', 'continuous')
    @sizeStick = @_makeJStick('size', 'static', true)
    @sync()
  enable: ->
  disable: ->
  active: -> true
  sync: ->
    @angleStick.sync()
    @sizeStick.sync()
  syncRulesAndIterations: ->

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
    if (parseFloat(input.val()) != value and not isNaN(parseFloat(value))) then input.val(value)

  toJson: -> return @update({})

  sync: (setting) ->
    _.chain(setting).omit("name").each( (v,k) => @setVal(k, v))
    return setting

  update: (setting) ->
    _.each(@el.find("[data-param]"), (el) =>
      key = $(el).data("param")
      val = @getVal(key)
      setting[key] = val if not isNaN(val)
    )
    return setting

class OffsetControl extends Control
  tpl: -> """
          <ul class="control-row">
          <li><input required data-param="x" type="text"></li><!--
          --><li><input required data-param="y" type="text"></li><!--
          --><li><input required data-param="rot" type="text"></li>
          </ul>
          """

class ParamControl extends Control
  tpl: -> """
          <ul class="control-row">
          <li class="label">#{@controlkey}</li><!--
          --><li><input required type="text" data-param="value"></li><!--
          --><li><input required type="text" data-param="growth"></li>
          </ul>
          """
  toJson: ->
    dummy = new Param(@controlkey, 0 , 0)
    return @update(dummy).toJson()

class SensitivityControl extends ParamControl
  toJson: ->
    dummy = new Sensitivity(@controlkey, 0, 0)
    return @update(dummy).toJson()
