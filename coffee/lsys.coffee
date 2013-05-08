
DefaultSystem = new LSystem(12, 12.27, 4187.5, """
 L : SS
 S : F-[F-Y[S(L]]
 Y : [-|F-F+)Y]
 """, "click-and-drag-me!")

#stores client mouse data
class Client
  down:false
  start:
    x:0
    y:0
  now:
    x:0
    y:0
  context:
    angle:0
    length:0

#yes this is an outrageous name for a .. system ... manager. buh.
class SystemManager
  client:null
  renderer:null
  currentSystem:null
  constructor: (@canvas, @controls) ->
    @client = new Client
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

  draw: ->
    t = @renderer.render(@currentSystem)
    #todo: get from bindings
    Util.control("rendered").innerHTML = "#{t}ms"
    $("#segments").html("#{@currentSystem.elements().length}")

  createBindings: ->
    document.onkeydown = (ev) =>
      if ev.keyCode == 13 and ev.ctrlKey
        @syncLocation()
      if ev.keyCode == 13 and ev.shiftKey
        @exportToPng()

    @canvas.onmousedown = (ev) =>
      @client.down = true
      @client.context.length = @currentSystem.size
      @client.context.angle = @currentSystem.angle
      @client.start.y = ev.clientY
      @client.start.x = ev.clientX
      return false

    document.onmouseup = =>
      @client.down = false
      location.hash = @currentSystem.toUrl()

    document.onmousemove = (ev) =>
      @client.now.x = ev.clientX
      @client.now.y = ev.clientY
      if (@client.down)
        $("#systemInfo").removeClass('blue')
        x = (@client.now.x - @client.start.x) / 10
        y = (@client.start.y - @client.now.y) / 100
        @currentSystem.angle = Util.round(x + @client.context.angle, 2)
        @currentSystem.size = Util.round(y + @client.context.length, 2)
        @syncControls()
        if not @renderer.isDrawing
          @draw()

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
