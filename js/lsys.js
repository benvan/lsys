(function() {

  window.lsys = function() {
    var bounding, canvas, client, clone, context, control, definitions, draw, elems, g, init, isDrawing, iterations, log, ruleMap, setupControls, stack, stringvalue, textRules, time, value;
    definitions = client = context = stack = elems = textRules = ruleMap = isDrawing = bounding = iterations = {};
    init = function() {
      var ang, c, cos, exp, expr, i, len, max, min, pi, r, s, sin, _i, _j, _len, _ref, _ref1;
      _ref = [Math.cos, Math.sin, Math.PI, Math.min, Math.max], cos = _ref[0], sin = _ref[1], pi = _ref[2], min = _ref[3], max = _ref[4];
      len = ang = s = c = 0;
      definitions = {
        "F": function(g) {
          len = context.incLength;
          ang = ((context.angle % 360) / 180) * pi;
          s = sin(ang);
          c = cos(ang);
          context.x += c * len;
          context.y += s * len;
          if (len > 0.1 || Math.random() < 0.3) {
            return g.lineTo(context.x, context.y);
          }
        },
        "+": function() {
          return context.angle += context.incAngle;
        },
        "-": function() {
          return context.angle -= context.incAngle;
        },
        "|": function() {
          return context.angle += 180;
        },
        "[": function() {
          return stack.push(clone(context));
        },
        "]": function() {
          context = stack.pop();
          return g.moveTo(context.x, context.y);
        },
        "!": function() {
          return context.incAngle *= -1;
        },
        "(": function() {
          return context.incAngle *= 0.95;
        },
        ")": function() {
          return context.incAngle *= 1.05;
        },
        "<": function() {
          return context.incLength *= 1.01;
        },
        ">": function() {
          return context.incLength *= 0.99;
        }
      };
      client = {
        down: false,
        start: {
          x: 0,
          y: 0
        },
        now: {
          x: 0,
          y: 0
        },
        context: {
          angle: 0,
          length: 0
        }
      };
      context = {
        x: 0,
        y: 0,
        angle: 0,
        incAngle: 0,
        incLength: 0
      };
      textRules = stringvalue('rules').split("\n").map(function(r) {
        return (r.replace(/\ /g, '')).split(':');
      });
      iterations = value("num");
      for (_i = 0, _len = textRules.length; _i < _len; _i++) {
        _ref1 = textRules[_i], r = _ref1[0], exp = _ref1[1];
        ruleMap[r] = exp;
      }
      expr = textRules[0][0];
      elems = [];
      for (i = _j = 1; 1 <= iterations ? _j <= iterations : _j >= iterations; i = 1 <= iterations ? ++_j : --_j) {
        expr = _.reduce(expr.split(""), (function(acc, symbol) {
          return acc + (ruleMap[symbol] || symbol);
        }), "");
      }
      elems = expr.split("");
      return setupControls();
    };
    setupControls = function() {
      document.onkeydown = function(ev) {
        if (ev.keyCode === 13 && ev.ctrlKey) {
          return window.lsys();
        }
      };
      canvas.onmousedown = function(ev) {
        client.down = true;
        client.context.length = value("length");
        client.context.angle = value("angle");
        client.start.y = ev.clientY;
        return client.start.x = ev.clientX;
      };
      document.onmouseup = function() {
        return client.down = false;
      };
      return document.onmousemove = function(ev) {
        var x, y;
        client.now.x = ev.clientX;
        client.now.y = ev.clientY;
        if (client.down) {
          x = (client.now.x - client.start.x) / 20;
          y = (client.start.y - client.now.y) / 100;
          control("angle").value = x + client.context.angle;
          control("length").value = y + client.context.length;
          if (!isDrawing) {
            return draw();
          }
        }
      };
    };
    log = function(x) {
      return console.log(x);
    };
    control = function(name) {
      return document.getElementById(name);
    };
    value = function(name) {
      return parseFloat(stringvalue(name));
    };
    stringvalue = function(name) {
      return control(name).value;
    };
    time = function(n, f) {
      var s;
      if (n instanceof Function) {
        f = n;
      }
      s = new Date;
      f();
      return new Date - s;
    };
    canvas = document.getElementById('c');
    g = canvas.getContext('2d');
    clone = function(c) {
      return {
        x: c.x,
        y: c.y,
        angle: c.angle,
        incAngle: c.incAngle,
        incLength: c.incLength
      };
    };
    draw = function() {
      var t;
      isDrawing = true;
      stack = [];
      bounding = {
        x1: Infinity,
        x2: 0,
        y1: Infinity,
        y2: 0
      };
      context = {
        x: canvas.width / 2,
        y: canvas.height / 2,
        angle: -90,
        incAngle: value("angle"),
        incLength: value("length")
      };
      g.globalAlpha = 1;
      g.fillStyle = "#202020";
      g.beginPath();
      g.rect(-1, -1, 700, 700);
      g.fill();
      g.closePath();
      g.lineWidth = 0.7;
      g.strokeStyle = "#fff";
      g.globalAlpha = 0.4;
      t = time(function() {
        g.moveTo(context.x, context.y);
        _.each(elems, function(e) {
          if (definitions[e]) {
            return definitions[e](g);
          }
        });
        return g.stroke();
      });
      control("rendered").innerText = t + "ms";
      control("segments").innerText = elems.length;
      return isDrawing = false;
    };
    init();
    return draw();
  };

}).call(this);
