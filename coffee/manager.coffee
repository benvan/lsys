
DefaultSystem = new LSystem({
    iterations: 12
    size: 12.27
    angle: 4187.5
  }
  ,"L : SS\nS : F-[F-Y[S(L]]\nY : [-|F-F+)Y]\n"
  ,"click-and-drag-me!"
)

class InputHandler
  snapshot: null # lsystem params as they were was when joystick activated
  constructor: (@keystate, @joystick) ->
  update: (params) =>
    return if not @joystick.active
    if (@keystate.alt)
      params.size = Util.round(params.size + @joystick.dy(200), 2)
      params.sizeGrowth += @joystick.dx(1000000)
    else
      params.angle = Util.round(params.angle + @joystick.dx(), 2)
      params.angleGrowth += @joystick.dy()


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
    @joystick.onActivate = => @inputHandler.snapshot = _.clone(@currentSystem.params)

    @renderer = new Renderer(canvas)
    @currentSystem = LSystem.fromUrl() or DefaultSystem
    @init()

  syncLocation: -> location.hash = @currentSystem.toUrl()

  updateFromControls: ->
    val = (n) -> parseFloat(n.val())
    @currentSystem = new LSystem(
      {
        iterations: val(@controls.iterations)
        size:       val(@controls.size.value)
        sizeGrowth: val(@controls.size.growth)
        angle:      val(@controls.angle.value)
        angleGrowth:val(@controls.angle.growth)
        sensitivity:{
          x: val(@controls.sensitivity.x)
          y: val(@controls.sensitivity.y)
        }
      }
      ,$(@controls.rules).val()
    )

  syncControls: ->
    params = @currentSystem.params
    $(@controls.iterations).val(params.iterations)
    $(@controls.rules).val(@currentSystem.rules)
    $(@controls.size.value).val(params.size)
    $(@controls.size.growth).val(params.sizeGrowth)
    $(@controls.angle.value).val(params.angle)
    $(@controls.angle.growth).val(params.angleGrowth)

  exportToPng: ->
    canvas = Util.control("c")
    [x,y] = [canvas.width / 2 , canvas.height / 2]

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
    @syncControls()

  run: ->
    @inputHandler.update(@currentSystem.params)
    if @joystick.active and not @renderer.isDrawing
      @draw()
      @syncControls()
    setTimeout((() => @run()), 10)

  draw: ->
    t = @renderer.render(@currentSystem)
    #todo: get from bindings
    $("#rendered").html("#{t}ms")
    $("#segments").html("#{@currentSystem.elements().length}")

  createBindings: ->
    document.onkeydown = (ev) =>
      if ev.keyCode == 13 and ev.ctrlKey
        @updateFromControls()
        @syncLocation()
      if ev.keyCode == 13 and ev.shiftKey
        @exportToPng()

    window.onhashchange = =>
      if location.hash != ""
        sys = LSystem.fromUrl()
        @currentSystem.merge(sys)
        @syncControls()
        @draw()

#===========================================

Util =
  log:(x) -> console.log(x)
  control:(name) -> document.getElementById(name)
  value: (name) => parseFloat(Util.stringvalue(name))
  stringvalue: (name) -> Util.control(name).value
  round: (n,d) ->
    pow = Math.pow(10,d)
    Math.round(n*pow) / pow
  time: (n,f) ->
    f = n if n instanceof Function
    s = new Date; f(); (new Date - s)
  openDataUrl: (data) ->
    a = document.createElement("a")
    a.href = data
    a.download="lsys/"+$("#systemName").text().replace(/[\ \/]/g,"_")
    evt = document.createEvent("MouseEvents")
    evt.initMouseEvent("click", true, true,window,0,0,0,0,0,true,false,false,false,0,null)
    a.dispatchEvent(evt)
