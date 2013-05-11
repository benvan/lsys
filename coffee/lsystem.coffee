class LSystem
  generatedElements:null #cache
  incAngle: 0.05
  incLength: 0.01
  rotAngle:180
  constructor: (@iterations, @size, @angle, @rules, @name) ->
  elements: =>
    if not @generatedElements
      @generate()
    return @generatedElements

  generate: =>
    textRules = @rules.split("\n").map (r) -> (r.replace(/\ /g, '')).split(':')

    ruleMap = {}
    ruleMap[r] = exp for [r,exp] in textRules

    expr = textRules[0][0]

    expr = _.reduce expr.split(""), ((acc, symbol) ->
      acc + (ruleMap[symbol] || symbol)
    ), "" for i in [1..@iterations]

    @generatedElements = expr.split("").filter((e) -> true if (Renderer.prototype.definitions[e]))

  merge: (system) =>
    @angle = system.angle
    @size = system.size
    @angle = system.angle
    if (!this.isIsomorphicTo(system))
      @rules = system.rules
      @iterations = system.iterations
      @generate()

  toUrl: =>
    params =
      it: @iterations
      l:  @size
      a:  @angle
      r:  encodeURIComponent(@rules)

    url = _.reduce(params,(acc,v,k) ->
      acc+k+"="+v+"&"
    ,"#")

    return url.substring(0,url.length-1)

  @fromUrl: (url = location.hash) ->
    return null if url == ""

    params = {}
    _.each(url.substring(1).split("&").map( (x) -> x.split("=")), ([k,v]) ->
      params[k] = v
    )

    return new LSystem(
      parseFloat(params.it)
    ,parseFloat(params.l)
    ,parseFloat(params.a)
    ,decodeURIComponent(params.r)
    )

  isIsomorphicTo: (system) => @rules == system.rules and @iterations == system.iterations
