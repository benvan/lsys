
DefaultSystem = new LSystem(12, 12.27, 4187.5, """
 L : SS
 S : F-[F-Y[S(L]]
 Y : [-|F-F+)Y]
 """, "click-and-drag-me!")

#yes this is an outrageous name for a .. system ... manager. buh.
class SystemManager
  client:null
  keystate: null
  renderer:null
  currentSystem:null
  constructor: (@canvas, @controls) ->
    @client = new Joystick(canvas)
    @keystate = new KeyState
    @renderer = new Renderer(canvas)
    @currentSystem = LSystem.fromUrl() or DefaultSystem
    @init()

  syncLocation: ->
    val = (n) -> parseFloat($("##{n}").val())
    location.hash = new LSystem(
       val("num")
      ,val("length")
      ,val("angle")
      ,$("#rules").val()
    ).toUrl()

  syncControls: ->
    sys = @currentSystem
    $("#num").val(sys.iterations)
    $("#length").val(sys.size)
    $("#angle").val(sys.angle)
    $("#rules").val(sys.rules)

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
    if @client.active
      @currentSystem.angle = Util.round(@currentSystem.angle + @client.dx(), 2)
      @currentSystem.incAngle = @currentSystem.incAngle + @client.dy()
      if not @renderer.isDrawing
        @draw()
      @syncControls()
    setTimeout((() => @run()), 10)

  draw: ->
    @client.clear();
    t = @renderer.render(@currentSystem)
    @client.draw();
    #todo: get from bindings
    Util.control("rendered").innerHTML = "#{t}ms"
    $("#segments").html("#{@currentSystem.elements().length}")

  createBindings: ->
    document.onkeydown = (ev) =>
      if ev.keyCode == 13 and ev.ctrlKey
        @syncLocation()
      if ev.keyCode == 13 and ev.shiftKey
        @exportToPng()

    document.onmouseup = =>
      @client.release()
      location.hash = @currentSystem.toUrl()

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
