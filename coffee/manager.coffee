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
      system.params.angle.value = Util.round(system.params.angle.value + @joystick.dx(system.sensitivities.angle.value), 4)
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

    @initControls()
    @joystick.disable()

  initControls: ->
    @createBindings()
    @createControls()

  syncLocation: -> location.hash = @systemManager.activeSystem.toUrl()
  syncLocationQuiet: -> location.quietSync = true; @syncLocation()

  beforeRecalculate: ->
  afterRecalculate: ->
  onRecalculateFail: ->
  onRecalculateProgress: ->

  isRecalculating: -> not @recalculationPromise or @recalculationPromise?.state() == 'pending'
  recalculate: (system = @lsystemFromControls()) ->
    @beforeRecalculate()
    @recalculationPromise = @systemManager.activate(system).progress(@onRecalculateProgress)
    @recalculationPromise.done( =>
      @joystick.enable()
      @syncAll();
      @draw()
      @afterRecalculate()
    )
    @recalculationPromise.fail(@onRecalculateFail)
    @recalculationPromise

  lsystemFromControls: ->
    return new LSystem(
      @paramControls.toJson(),
      @offsetControls.toJson(),
      @sensitivityControls.toJson(),
      $(@controls.rules).val(),
      parseInt($(@controls.iterations).val()),
      $(@controls.name).val()
    )

  exportToPng: (system = @systemManager.activeSystem) ->
    [x,y] = [(Util.canvasWidth(@canvas) / 2) + system.offsets.x, (Util.canvasHeight(@canvas) / 2) + system.offsets.y]

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

    @draw(r)
    filename = "lsys_"+system.name.replace(/[\ \/]/g,"_")
    Util.openDataUrl( c.toDataURL("image/png"), filename )

  start: ->
    startingSystem = LSystem.fromUrl() or DefaultSystem
    @recalculate(startingSystem)
      .fail( => @syncAll(startingSystem) )
      .pipe( => @draw())
      .always(@run)

  run: =>
    setTimeout(@run, 10)
    @inputHandler.update(@systemManager.activeSystem)
    if @joystick.active and not @renderer.isDrawing
      @draw()
      @joystick.draw()
      @syncControls()

  draw: (renderer = @renderer) =>
      elems = @systemManager.getInstructions()
      renderer.render(elems, @systemManager.activeSystem) if elems

  createControls: ->
    @paramControls = new Controls(Defaults.params(), ParamControl)
    @offsetControls = new OffsetControl(Defaults.offsets())
    @sensitivityControls = new Controls(Defaults.sensitivities(), SensitivityControl)

    @paramControls.create(@controls.params)
    @offsetControls.create(@controls.offsets)
    @sensitivityControls.create(@controls.sensitivities)

  syncAll: (system = @systemManager.activeSystem) ->
    $(@controls.name).val(system.name)
    @syncControls(system)
    @syncRulesAndIterations(system)

  syncRulesAndIterations: (system = @systemManager.activeSystem) ->
    $(@controls.iterations).val(system.iterations)
    $(@controls.rules).val(system.rules)

  syncControls: (system = @systemManager.activeSystem) ->
    @paramControls.sync(system.params)
    @offsetControls.sync(system.offsets)
    @sensitivityControls.sync(system.sensitivities)

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
