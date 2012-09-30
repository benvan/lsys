lsys.util =
  log:(x) -> console.log(x)
  control:(name) -> document.getElementById(name)
  value: (name) => parseFloat(lsys.util.stringvalue(name))
  stringvalue: (name) -> lsys.util.control(name).value
  round: (n,d) ->
    pow = Math.pow(10,d)
    Math.round(n*pow) / pow
  time: (n,f) ->
    f = n if n instanceof Function
    s = new Date; f(); (new Date - s)

lsys.client = new lsys.Client
lsys.renderer = new lsys.Renderer(lsys.util.control("c"))
lsys.currentSystem = lsys.LSystem.fromUrl() or new lsys.LSystem(12, 14.07, 3104.4, """
L : SS
S : F-[F-Y[S)L]]
Y : [|F-F+)Y]
""", "click-and-drag-me!")

lsys.go = ->
  val = (n) -> parseFloat($("##{n}").val())
  location.hash = new lsys.LSystem(
     val("num")
    ,val("length")
    ,val("angle")
    ,$("#rules").val()
  ).toUrl()



lsys.draw = ->
  t = lsys.renderer.render(lsys.currentSystem)
  lsys.util.control("rendered").innerHTML = "#{t}ms"
  $("#segments").html("#{lsys.currentSystem.elements().length}")

lsys.init = ->
  canvas = lsys.util.control("c")
  document.onkeydown = (ev) ->
    if ev.keyCode == 13 and ev.ctrlKey
      lsys.go()

  canvas.onmousedown = (ev) ->
    client = lsys.client
    client.down = true
    client.context.length = lsys.currentSystem.size
    client.context.angle = lsys.currentSystem.angle
    client.start.y = ev.clientY
    client.start.x = ev.clientX
    return false

  document.onmouseup = ->
    lsys.client.down = false
    location.hash = lsys.currentSystem.toUrl()

  stretchCanvas = ->
    window.container = lsys.util.control("drawingContainer")
    canvas.width = container.clientWidth
    canvas.height = container.clientHeight

  stretchCanvas()

  $(window).resize( ->
    clearTimeout(window.resizeTimer);
    window.resizeTimer = setTimeout( ->
      stretchCanvas()
      lsys.draw()
    , 300);
  )

  document.onmousemove = (ev) ->
    client = lsys.client
    system = lsys.currentSystem
    client.now.x = ev.clientX
    client.now.y = ev.clientY
    if (client.down)
      $("#systemInfo").removeClass('blue')
      x = (client.now.x - client.start.x) / 10
      y = (client.start.y - client.now.y) / 100
      system.angle = lsys.util.round(x + client.context.angle, 2)
      system.size = lsys.util.round(y + client.context.length, 2)
      lsys.updateView()
      if not lsys.renderer.isDrawing
        lsys.draw()

  window.onhashchange = ->
    if location.hash != ""
      sys = lsys.LSystem.fromUrl()
#      if (lsys.currentSystem.rules != sys.rules)
#        $("#systemInfo").slideUp();
      lsys.currentSystem.merge(sys)
      lsys.updateView()
      lsys.draw()


lsys.updateView = ->
  sys = lsys.currentSystem
  $("#num").val(sys.iterations)
  $("#length").val(sys.size)
  $("#angle").val(sys.angle)
  $("#rules").val(sys.rules)

lsys.init()
lsys.updateView()