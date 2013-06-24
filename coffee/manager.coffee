
DefaultSystem = new LSystem({
    size: {value:12.27}
    angle: {value:4187.5}
  },
  {}
  ,"L : SS\nS : F-[F-Y[S(L]]\nY : [-|F-F+)Y]\n"
  ,12
  ,"click-and-drag-me!"
)

class InputHandler
  snapshot: null # lsystem params as they were was when joystick activated
  constructor: (@keystate, @joystick) ->
  update: (system) =>
    return if not @joystick.active
    if (@keystate.alt)
      system.params.size.value = Util.round(system.params.size.value + @joystick.dy(200), 2)
      system.params.size.growth += @joystick.dx(1000000)
    else if (@keystate.cmd or @keystate.ctrl)
      system.offsets.x = @snapshot.offsets.x + @joystick.dx(1)
      system.offsets.y = @snapshot.offsets.y + @joystick.dy(1)
    else
      system.params.angle.value = Util.round(system.params.angle.value + @joystick.dx(), 2)
      system.params.angle.growth += @joystick.dy()


#yes this is an outrageous name for a .. system ... manager. buh.
class SystemManager
  joystick:null
  keystate: null
  inputHandler: null
  renderer:null
  currentSystem:null
  constructor: (@canvas, @controls) ->
    @joystick = new Joystick(canvas)
    @keystate = new KeyState
    @inputHandler = new InputHandler(@keystate, @joystick)

    @joystick.onRelease = => location.hash = @currentSystem.toUrl()
    @joystick.onActivate = => @inputHandler.snapshot = @currentSystem.clone()

    @renderer = new Renderer(canvas)
    @currentSystem = LSystem.fromUrl() or DefaultSystem
    @init()

  syncLocation: -> location.hash = @currentSystem.toUrl()

  updateFromControls: ->
    @currentSystem = new LSystem(
      @paramControls.toJson(),
      @offsetControls.toJson(),
      $(@controls.rules).val(),
      parseInt($(@controls.iterations).val()),
      @currentSystem.name
    )

  exportToPng: ->
    [x,y] = [@canvas.width / 2 , @canvas.height / 2]

    b = @renderer.context.bounding
    c = $('<canvas></canvas>').attr({
      "width" : b.width()+30,
      "height": b.height()+30
    })[0]

    r = new Renderer(c)
    r.reset = (system) ->
      r.context.reset(system)
      r.context.state.x = (x-b.x1+15)
      r.context.state.y = (y-b.y1+15)

    r.render(@currentSystem)
    Util.openDataUrl(c.toDataURL("image/png"))

  init: ->
    @createBindings()
    @createControls()
    @syncControls()

  run: ->
    @inputHandler.update(@currentSystem)
    if @joystick.active and not @renderer.isDrawing
      @draw()
      @syncControls()
    setTimeout((() => @run()), 10)

  draw: ->
    t = @renderer.render(@currentSystem)
    #todo: get from bindings
    $("#rendered").html("#{t}ms")
    $("#segments").html("#{@currentSystem.elements().length}")

  createControls: ->
    @paramControls = new Controls(LSystem.defaultParams(), ParamControl)
    @offsetControls = new OffsetControl(LSystem.defaultOffsets())

    @paramControls.create(@controls.params)
    @offsetControls.create(@controls.offsets)

  syncControls: ->
    $(@controls.iterations).val(@currentSystem.iterations)
    $(@controls.rules).val(@currentSystem.rules)
    @paramControls.sync(@currentSystem.params)
    @offsetControls.sync(@currentSystem.offsets)
    $(@controls.offsets.x).val(@currentSystem.offsets.x)
    $(@controls.offsets.y).val(@currentSystem.offsets.y)
    $(@controls.offsets.rot).val(@currentSystem.offsets.rot)


  createBindings: ->
    document.onkeydown = (ev) =>
      if ev.keyCode == 13 and ev.ctrlKey
        @updateFromControls()
        @syncLocation()
      if ev.keyCode == 13 and ev.shiftKey
        @exportToPng()
      if (ev.metaKey or ev.ctrlKey)
        $(@canvas).addClass('moving')

    document.onkeyup = (ev) =>
      if not (ev.metaKey or ev.ctrlKey)
        $(@canvas).removeClass('moving')

    window.onhashchange = =>
      if location.hash != ""
        sys = LSystem.fromUrl()
        @currentSystem.merge(sys)
        @syncControls()
        @draw()

#===========================================