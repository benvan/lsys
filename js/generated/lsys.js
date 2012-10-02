(function() {
  var _this = this;

  lsys.util = {
    log: function(x) {
      return console.log(x);
    },
    control: function(name) {
      return document.getElementById(name);
    },
    value: function(name) {
      return parseFloat(lsys.util.stringvalue(name));
    },
    stringvalue: function(name) {
      return lsys.util.control(name).value;
    },
    round: function(n, d) {
      var pow;
      pow = Math.pow(10, d);
      return Math.round(n * pow) / pow;
    },
    time: function(n, f) {
      var s;
      if (n instanceof Function) {
        f = n;
      }
      s = new Date;
      f();
      return new Date - s;
    }
  };

  lsys.client = new lsys.Client;

  lsys.renderer = new lsys.Renderer(lsys.util.control("c"));

  lsys.currentSystem = lsys.LSystem.fromUrl() || new lsys.LSystem(12, 14.07, 3104.4, "L : SS\nS : F-[F-Y[S)L]]\nY : [|F-F+)Y]", "click-and-drag-me!");

  lsys.go = function() {
    var val;
    val = function(n) {
      return parseFloat($("#" + n).val());
    };
    return location.hash = new lsys.LSystem(val("num"), val("length"), val("angle"), $("#rules").val()).toUrl();
  };

  lsys.draw = function() {
    var t;
    t = lsys.renderer.render(lsys.currentSystem);
    lsys.util.control("rendered").innerHTML = "" + t + "ms";
    return $("#segments").html("" + (lsys.currentSystem.elements().length));
  };

  lsys.init = function() {
    var canvas, stretchCanvas;
    canvas = lsys.util.control("c");
    document.onkeydown = function(ev) {
      if (ev.keyCode === 13 && ev.ctrlKey) {
        return lsys.go();
      }
    };
    canvas.onmousedown = function(ev) {
      var client;
      client = lsys.client;
      client.down = true;
      client.context.length = lsys.currentSystem.size;
      client.context.angle = lsys.currentSystem.angle;
      client.start.y = ev.clientY;
      client.start.x = ev.clientX;
      return false;
    };
    document.onmouseup = function() {
      lsys.client.down = false;
      return location.hash = lsys.currentSystem.toUrl();
    };
    stretchCanvas = function() {
      window.container = lsys.util.control("drawingContainer");
      canvas.width = container.clientWidth;
      return canvas.height = container.clientHeight;
    };
    stretchCanvas();
    $(window).resize(function() {
      clearTimeout(window.resizeTimer);
      return window.resizeTimer = setTimeout(function() {
        stretchCanvas();
        return lsys.draw();
      }, 300);
    });
    document.onmousemove = function(ev) {
      var client, system, x, y;
      client = lsys.client;
      system = lsys.currentSystem;
      client.now.x = ev.clientX;
      client.now.y = ev.clientY;
      if (client.down) {
        $("#systemInfo").removeClass('blue');
        x = (client.now.x - client.start.x) / 10;
        y = (client.start.y - client.now.y) / 100;
        system.angle = lsys.util.round(x + client.context.angle, 2);
        system.size = lsys.util.round(y + client.context.length, 2);
        lsys.updateView();
        if (!lsys.renderer.isDrawing) {
          return lsys.draw();
        }
      }
    };
    return window.onhashchange = function() {
      var sys;
      if (location.hash !== "") {
        sys = lsys.LSystem.fromUrl();
        lsys.currentSystem.merge(sys);
        lsys.updateView();
        return lsys.draw();
      }
    };
  };

  lsys.updateView = function() {
    var sys;
    sys = lsys.currentSystem;
    $("#num").val(sys.iterations);
    $("#length").val(sys.size);
    $("#angle").val(sys.angle);
    return $("#rules").val(sys.rules);
  };

  lsys.init();

  lsys.updateView();

}).call(this);
