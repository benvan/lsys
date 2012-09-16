(function() {

  window.lsys = function() {
    var activeSystem, bounding, canvas, client, clone, context, control, definitions, draw, elems, g, generate, init, initFromUrl, isDrawing, iterations, log, mkurl, readurl, round, ruleMap, setupControls, stack, stringvalue, textRules, time, value;
    definitions = client = context = stack = elems = textRules = ruleMap = isDrawing = bounding = activeSystem = iterations = {};
    init = function() {
      var ang, c, cos, len, max, min, pi, s, sin, _ref;
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
          return g.lineTo(context.x, context.y);
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
      generate();
      setupControls();
      return initFromUrl();
    };
    generate = function() {
      var exp, expr, i, r, _i, _j, _len, _ref;
      activeSystem = stringvalue('rules');
      textRules = activeSystem.split("\n").map(function(r) {
        return (r.replace(/\ /g, '')).split(':');
      });
      iterations = value("num");
      for (_i = 0, _len = textRules.length; _i < _len; _i++) {
        _ref = textRules[_i], r = _ref[0], exp = _ref[1];
        ruleMap[r] = exp;
      }
      expr = textRules[0][0];
      elems = [];
      for (i = _j = 1; 1 <= iterations ? _j <= iterations : _j >= iterations; i = 1 <= iterations ? ++_j : --_j) {
        expr = _.reduce(expr.split(""), (function(acc, symbol) {
          return acc + (ruleMap[symbol] || symbol);
        }), "");
      }
      return elems = expr.split("").filter(function(e) {
        if (definitions[e]) {
          return true;
        }
      });
    };
    setupControls = function() {
      document.onkeydown = function(ev) {
        if (ev.keyCode === 13 && ev.ctrlKey) {
          location.hash = mkurl();
          return window.lsys();
        }
      };
      canvas.onmousedown = function(ev) {
        client.down = true;
        client.context.length = value("length");
        client.context.angle = value("angle");
        client.start.y = ev.clientY;
        client.start.x = ev.clientX;
        return false;
      };
      document.onmouseup = function() {
        client.down = false;
        return location.hash = mkurl();
      };
      document.onmousemove = function(ev) {
        var x, y;
        client.now.x = ev.clientX;
        client.now.y = ev.clientY;
        if (client.down) {
          x = (client.now.x - client.start.x) / 10;
          y = (client.start.y - client.now.y) / 100;
          control("angle").value = round(x + client.context.angle, 2);
          control("length").value = round(y + client.context.length, 2);
          if (!isDrawing) {
            isDrawing = true;
            return draw();
          }
        }
      };
      return window.onhashchange = initFromUrl;
    };
    initFromUrl = function() {
      var params, prevNum;
      if (location.hash !== "") {
        params = readurl();
        prevNum = control("num").value;
        control("num").value = params.it;
        control("length").value = params.l;
        control("angle").value = params.a;
        control("rules").value = decodeURIComponent(params.r);
        if (activeSystem !== stringvalue("rules") || prevNum !== params.it) {
          generate();
        }
        return draw();
      }
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
    round = function(n, d) {
      var pow;
      pow = Math.pow(10, d);
      return Math.round(n * pow) / pow;
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
    mkurl = function() {
      var params, url;
      params = {
        it: value("num"),
        l: value("length"),
        a: value("angle"),
        r: encodeURIComponent(stringvalue("rules"))
      };
      url = _.reduce(params, function(acc, v, k) {
        return acc + k + "=" + v + "&";
      }, "#");
      return url.substring(0, url.length - 1);
    };
    readurl = function() {
      var params;
      params = {};
      _.each(location.hash.substring(1).split("&").map(function(x) {
        return x.split("=");
      }), function(_arg) {
        var k, v;
        k = _arg[0], v = _arg[1];
        return params[k] = v;
      });
      return params;
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
      g.clearRect(0, 0, 700, 700);
      g.fill();
      g.closePath();
      g.lineWidth = 0.4;
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
      control("rendered").innerHTML = t + "ms";
      control("segments").innerHTML = elems.length;
      return isDrawing = false;
    };
    init();
    return draw();
  };

}).call(this);
