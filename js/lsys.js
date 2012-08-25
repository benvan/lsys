(function() {

  window.go = function() {
    var canvas, clone, context, control, cos, exp, expr, functions, g, i, iterations, r, rule, rules, s, sin, stack, start, time, value, x, _i, _j, _len, _ref;
    control = function(name) {
      return document.getElementById(name);
    };
    value = function(name) {
      return control(name).value;
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
    context = {
      x: canvas.width / 2,
      y: canvas.height / 2,
      angle: 0,
      incAngle: value("angle"),
      incLength: value("length")
    };
    rules = document.getElementById('rules').value;
    rules = rules.split("\n").map(function(rule) {
      return rule.split(" : ");
    });
    rule = {};
    for (_i = 0, _len = rules.length; _i < _len; _i++) {
      _ref = rules[_i], r = _ref[0], exp = _ref[1];
      rule[r] = exp;
    }
    iterations = value("num");
    s = new Date;
    start = rule[rules[0][0]];
    stack = [];
    expr = start;
    for (i = _j = 1; 1 <= iterations ? _j <= iterations : _j >= iterations; i = 1 <= iterations ? ++_j : --_j) {
      expr = _.reduce(expr.split(""), (function(acc, symbol) {
        return acc + (rule[symbol] || symbol);
      }), "");
    }
    control("generated").innerText = new Date - s;
    window.test = expr;
    cos = Math.cos;
    sin = Math.sin;
    functions = {
      "F": function(g) {},
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
    g.globalAlpha = 1;
    g.fillStyle = "#202020";
    g.beginPath();
    g.rect(0, 0, 1000, 1000);
    g.fill();
    g.closePath();
    g.lineWidth = 0.4;
    g.strokeStyle = "#fff";
    g.globalAlpha = 0.4;
    time = function(f) {
      s = new Date;
      f();
      return console.log(new Date - s);
    };
    time(function(f) {
      return expr.split("");
    });
    console.log(expr.length);
    x = _.map([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], function(i) {
      s = new Date;
      _.each(expr, function(e) {
        return functions[e] && functions[e](g);
      });
      return new Date() - s;
    });
    return control("rendered").innerText = (_.reduce(x, function(x, y) {
      return x + y;
    })) / x.length;
  };

}).call(this);
