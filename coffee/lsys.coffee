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
lsys.currentSystem = new lsys.LSystem(12, 14.07, 3104.4, """
L : SS
S : F-[F-Y[S)L]]
Y : [|F-F+)Y]
""", "click-and-drag-me!")


lsys.draw = -> lsys.renderer.render(lsys.currentSystem)
lsys.init = ->
  canvas = lsys.util.control("c")
  document.onkeydown = (ev) ->
    if ev.keyCode == 13 and ev.ctrlKey
      location.hash = lsys.currentSystem.toUrl()

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
        t = lsys.draw()
        lsys.util.control("rendered").innerHTML = "#{t}ms"

  window.onhashchange = ->
    if location.hash != ""
      sys = lsys.LSystem.fromUrl()
      if not sys.isIsomorphicTo(lsys.currentSystem)
        lsys.currentSystem = sys
        lsys.draw()


lsys.updateView = ->
  c = lsys.util.control
  sys = lsys.currentSystem
  c("num").value = sys.iterations
  c("length").value = sys.size
  c("angle").value = sys.angle
  c("rules").html = sys.rules

lsys.init()