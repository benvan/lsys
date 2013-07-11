class InputHandler
  snapshot: null # lsystem params as they were was when joystick activated
  constructor: (@keystate, @joystick) ->
  update: (system) =>
    return if not @joystick.active
    if (@keystate.alt)
      system.params.size.value = Util.round(@snapshot.params.size.value + (@joystick.dy(system.sensitivities.size.value)), 2)
      system.params.size.growth = Util.round(@snapshot.params.size.growth + @joystick.dx(system.sensitivities.size.growth),6)
    else if (@keystate.meta or @keystate.ctrl)
      system.offsets.x = @snapshot.offsets.x + @joystick.dx()
      system.offsets.y = @snapshot.offsets.y + @joystick.dy()
    else
      system.params.angle.value = Util.round(system.params.angle.value + @joystick.dx(system.sensitivities.angle.value), 2)
      system.params.angle.growth = Util.round(system.params.angle.growth + @joystick.dy(system.sensitivities.angle.growth),9)


class AppManager
  joystick:null
  keystate: null
  inputHandler: null
  renderer:null
  systemManager: null

  constructor: (@canvas, @controls) ->
    @joystick = new Joystick(canvas)
    @keystate = new KeyState
    @inputHandler = new InputHandler(@keystate, @joystick)

    @joystick.onRelease = => @syncLocationQuiet()
    @joystick.onActivate = => @inputHandler.snapshot = @systemManager.activeSystem.clone()

    @renderer = new Renderer(canvas)

    @systemManager = new SystemManager
    @initialised = @systemManager.activate(LSystem.fromUrl() or DefaultSystem).pipe(@init)

  syncLocation: -> location.hash = @systemManager.activeSystem.toUrl()
  syncLocationQuiet: -> location.quietSync = true; @syncLocation()

  recalculate: (system = @lsystemFromControls()) ->
    @systemManager.activate(system).done( => @syncAll(); @draw() )

  lsystemFromControls: ->
    return new LSystem(
      @paramControls.toJson(),
      @offsetControls.toJson(),
      @sensitivityControls.toJson(),
      $(@controls.rules).val(),
      parseInt($(@controls.iterations).val()),
      @systemManager.activeSystem.name
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

    @draw(r).then( -> Util.openDataUrl(c.toDataURL("image/png")) )

  init: =>
    @createBindings()
    @createControls()
    @syncAll()

  start: -> @initialised.pipe(@draw).pipe(@run)
  run: =>
    setTimeout(@run, 10)
    @inputHandler.update(@systemManager.activeSystem)
    if @joystick.active and not @renderer.isDrawing
      @draw()
      @joystick.draw()
      @syncControls()

  draw: (renderer = @renderer) =>
    @systemManager.getInstructions().pipe( (elements) =>
      @renderer.render(elements, @systemManager.activeSystem)
    )

  createControls: ->
    @paramControls = new Controls(Defaults.params(), ParamControl)
    @offsetControls = new OffsetControl(Defaults.offsets())
    @sensitivityControls = new Controls(Defaults.sensitivities(), SensitivityControl)

    @paramControls.create(@controls.params)
    @offsetControls.create(@controls.offsets)
    @sensitivityControls.create(@controls.sensitivities)

  syncAll: ->
    @syncControls()
    @syncRulesAndIterations()

  syncRulesAndIterations: ->
    $(@controls.iterations).val(@systemManager.activeSystem.iterations)
    $(@controls.rules).val(@systemManager.activeSystem.rules)

  syncControls: ->
    @paramControls.sync(@systemManager.activeSystem.params)
    @offsetControls.sync(@systemManager.activeSystem.offsets)
    @sensitivityControls.sync(@systemManager.activeSystem.sensitivities)

  createBindings: ->
    setClassIf = (onOff, className) =>
      method = if (onOff) then 'add' else 'remove'
      $(@canvas)["#{method}Class"](className)

    updateCursorType = (ev) =>
      setClassIf(ev.ctrlKey or ev.metaKey, "moving")
      setClassIf(ev.altKey, "resizing")

    document.addEventListener("keydown", (ev) =>
      updateCursorType(ev)
      if ev.keyCode == Key.enter and ev.ctrlKey
        @recalculate()
        @syncLocation()
        return false
      if ev.keyCode == Key.enter and ev.shiftKey
        @exportToPng()
    )

    document.addEventListener("keyup", updateCursorType)
    document.addEventListener("mousedown", updateCursorType)

    window.onhashchange = =>
      quiet = location.quietSync
      location.quietSync = false
      if location.hash != "" && !quiet
        @recalculate(LSystem.fromUrl())


#===========================================
