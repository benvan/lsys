(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.lsys = {};

  lsys.Client = (function() {

    Client.name = 'Client';

    function Client() {}

    Client.prototype.down = false;

    Client.prototype.start = {
      x: 0,
      y: 0
    };

    Client.prototype.now = {
      x: 0,
      y: 0
    };

    Client.prototype.context = {
      angle: 0,
      length: 0
    };

    return Client;

  })();

  lsys.Bounding = (function() {

    Bounding.name = 'Bounding';

    function Bounding() {
      this.height = __bind(this.height, this);

      this.width = __bind(this.width, this);

    }

    Bounding.prototype.x1 = Infinity;

    Bounding.prototype.y1 = Infinity;

    Bounding.prototype.x2 = -Infinity;

    Bounding.prototype.y2 = -Infinity;

    Bounding.prototype.width = function() {
      return this.x2 - this.x1;
    };

    Bounding.prototype.height = function() {
      return this.y2 - this.y1;
    };

    return Bounding;

  })();

  window.lsys.LSystem = (function() {

    LSystem.name = 'LSystem';

    function LSystem(iterations, size, angle, rules, name) {
      this.iterations = iterations;
      this.size = size;
      this.angle = angle;
      this.rules = rules;
      this.name = name;
      this.isIsomorphicTo = __bind(this.isIsomorphicTo, this);

      this.toUrl = __bind(this.toUrl, this);

      this.merge = __bind(this.merge, this);

      this.generate = __bind(this.generate, this);

      this.elements = __bind(this.elements, this);

    }

    LSystem.prototype.elements = function() {
      if (!this.generatedElements) {
        this.generate();
      }
      return this.generatedElements;
    };

    LSystem.prototype.generate = function() {
      var exp, expr, i, r, ruleMap, textRules, _i, _j, _len, _ref, _ref1;
      textRules = this.rules.split("\n").map(function(r) {
        return (r.replace(/\ /g, '')).split(':');
      });
      ruleMap = {};
      for (_i = 0, _len = textRules.length; _i < _len; _i++) {
        _ref = textRules[_i], r = _ref[0], exp = _ref[1];
        ruleMap[r] = exp;
      }
      expr = textRules[0][0];
      for (i = _j = 1, _ref1 = this.iterations; 1 <= _ref1 ? _j <= _ref1 : _j >= _ref1; i = 1 <= _ref1 ? ++_j : --_j) {
        expr = _.reduce(expr.split(""), (function(acc, symbol) {
          return acc + (ruleMap[symbol] || symbol);
        }), "");
      }
      return this.generatedElements = expr.split("").filter(function(e) {
        if (lsys.renderer.definitions[e]) {
          return true;
        }
      });
    };

    LSystem.prototype.merge = function(system) {
      this.angle = system.angle;
      this.size = system.size;
      this.angle = system.angle;
      if (!this.isIsomorphicTo(system)) {
        this.rules = system.rules;
        this.iterations = system.iterations;
        return this.generate();
      }
    };

    LSystem.prototype.toUrl = function() {
      var params, url;
      params = {
        it: this.iterations,
        l: this.size,
        a: this.angle,
        r: encodeURIComponent(this.rules)
      };
      url = _.reduce(params, function(acc, v, k) {
        return acc + k + "=" + v + "&";
      }, "#");
      return url.substring(0, url.length - 1);
    };

    LSystem.fromUrl = function() {
      var params;
      if (location.hash === "") {
        return null;
      }
      params = {};
      _.each(location.hash.substring(1).split("&").map(function(x) {
        return x.split("=");
      }), function(_arg) {
        var k, v;
        k = _arg[0], v = _arg[1];
        return params[k] = v;
      });
      return new LSystem(parseFloat(params.it), parseFloat(params.l), parseFloat(params.a), decodeURIComponent(params.r));
    };

    LSystem.prototype.isIsomorphicTo = function(system) {
      return this.rules === system.rules && this.iterations === system.iterations;
    };

    return LSystem;

  })();

  window.lsys.RenderingContext = (function() {

    RenderingContext.name = 'RenderingContext';

    function RenderingContext(canvas, system) {
      this.state = {
        x: canvas.width / 2,
        y: canvas.height / 2,
        angle: -90,
        incAngle: system.angle,
        incLength: system.size
      };
      this.bounding = new lsys.Bounding;
      this.stack = [];
    }

    return RenderingContext;

  })();

  window.lsys.Renderer = (function() {

    Renderer.name = 'Renderer';

    Renderer.prototype.isDrawing = false;

    Renderer.prototype.context = void 0;

    Renderer.prototype.stack = [];

    Renderer.prototype.g = void 0;

    function Renderer(canvas) {
      this.canvas = canvas;
      this.render = __bind(this.render, this);

      this.reset = __bind(this.reset, this);

      this.clearCanvas = __bind(this.clearCanvas, this);

      this.g = canvas.getContext("2d");
    }

    Renderer.prototype.clearCanvas = function() {
      var b, p, padding;
      if (this.context) {
        b = this.context.bounding;
        p = padding = 5;
        return this.g.clearRect(b.x1 - p, b.y1 - p, b.width() + 2 * p, b.height() + 2 * p);
      }
    };

    Renderer.prototype.reset = function(system) {
      this.clearCanvas();
      return this.context = new lsys.RenderingContext(this.canvas, system);
    };

    Renderer.prototype.render = function(system) {
      var b, s, start, _ref, _ref1,
        _this = this;
      this.isDrawing = true;
      start = new Date;
      this.reset(system);
      this.g.lineWidth = 0.4;
      this.g.strokeStyle = "#fff";
      this.g.globalAlpha = 0.4;
      this.g.beginPath();
      this.g.moveTo(this.context.state.x, this.context.state.y);
      _ref = [this.context.state, this.context.bounding], s = _ref[0], b = _ref[1];
      _ref1 = [s.x, s.y], b.x2 = _ref1[0], b.y2 = _ref1[1];
      _.each(system.elements(), function(e) {
        if (_this.definitions[e]) {
          return _this.definitions[e](_this.context.state, _this.g, _this.context);
        }
      });
      this.g.stroke();
      this.g.closePath();
      this.isDrawing = false;
      return new Date - start;
    };

    Renderer.prototype.definitions = (function() {
      var ang, c, cloneState, cos, len, max, min, pi, s, sin, _ref;
      _ref = [Math.cos, Math.sin, Math.PI, Math.min, Math.max], cos = _ref[0], sin = _ref[1], pi = _ref[2], min = _ref[3], max = _ref[4];
      len = ang = s = c = 0;
      cloneState = function(c) {
        return {
          x: c.x,
          y: c.y,
          angle: c.angle,
          incAngle: c.incAngle,
          incLength: c.incLength
        };
      };
      return {
        "F": function(state, g, context) {
          var bounding;
          len = state.incLength;
          ang = ((state.angle % 360) / 180) * pi;
          s = sin(ang);
          c = cos(ang);
          state.x += c * len;
          state.y += s * len;
          bounding = context.bounding;
          if (state.x < bounding.x1) {
            bounding.x1 = state.x;
          } else if (state.x > bounding.x2) {
            bounding.x2 = state.x;
          }
          if (state.y < bounding.y1) {
            bounding.y1 = state.y;
          } else if (state.y > bounding.y2) {
            bounding.y2 = state.y;
          }
          return g.lineTo(state.x, state.y);
        },
        "+": function(state) {
          return state.angle += state.incAngle;
        },
        "-": function(state) {
          return state.angle -= state.incAngle;
        },
        "|": function(state) {
          return state.angle += 180;
        },
        "[": function(state, g, context) {
          return context.stack.push(cloneState(state));
        },
        "]": function(state, g, context) {
          context.state = state = context.stack.pop();
          return g.moveTo(state.x, state.y);
        },
        "!": function(state) {
          return state.incAngle *= -1;
        },
        "(": function(state) {
          return state.incAngle *= 0.95;
        },
        ")": function(state) {
          return state.incAngle *= 1.05;
        },
        "<": function(state) {
          return state.incLength *= 1.01;
        },
        ">": function(state) {
          return state.incLength *= 0.99;
        }
      };
    })();

    return Renderer;

  })();

}).call(this);
