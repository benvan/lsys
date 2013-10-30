class AppManager
  renderer:null
  systemManager: null

  constructor: (@canvas, controlBuilder) ->

    @renderer = new Renderer(canvas)

    @systemManager = new SystemManager

    @createBindings()
    @controls = controlBuilder(this)
    @controls.disable()

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
      @controls.enable()
      @syncAll()
      @draw()
      @afterRecalculate()
    )
    @recalculationPromise.fail(@onRecalculateFail)
    @recalculationPromise

  getCurrentSystem: -> @systemManager.activeSystem

  lsystemFromControls: -> @controls.toLSystem()

  exportToPng: (system = @systemManager.activeSystem) ->
    [x,y] = [(@canvas.width / 2) + system.offsets.x, (@canvas.height / 2) + system.offsets.y]

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
    if @controls.active and not @renderer.isDrawing
      @draw()
    requestAnimationFrame(@run)

  draw: (renderer = @renderer) =>
      elems = @systemManager.getInstructions()
      renderer.render(elems, @systemManager.activeSystem) if elems

  syncAll: (system = @systemManager.activeSystem) ->
    @controls.sync(system)

  syncRulesAndIterations: (system = @systemManager.activeSystem) ->
    @controls.syncRulesAndIterations(system)

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
