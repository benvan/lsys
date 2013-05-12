class LSystem
  generatedElements:null #cache
  params: null
  defaultParams: {
    iterations: 1
    size: 1
    sizeGrowth: 0.01
    angle: 1
    angleGrowth: 0.05
  }
  constructor: (params, @rules, @name) ->
    @params = _.clone(@defaultParams)
    for key of params then do =>
      @params[key] = params[key] || @params[key]

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
    ), "" for i in [1..@params.iterations]

    @generatedElements = expr.split("").filter((e) -> true if (Renderer.prototype.definitions[e]))

  # update yourself to look like system (avoiding regeneration where possible)
  merge: (system) =>
    wasIsomorphic = @isIsomorphicTo(system)
    _.extend(@, {
      rules: system.rules,
      params: system.params
    })
    @generate() if not wasIsomorphic


  # this is not the most efficient of methods... (it's also currently broken - inc{Angle,Length} omitted)
  clone: -> return new LSystem.fromUrl(@toUrl())

  toUrl: =>
    params =
      it: @params.iterations
      l:  @params.size #todo: make consistent
      sg: @params.sizeGrowth
      a:  @params.angle
      ag: @params.angleGrowth
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
      params[k] = (parseFloat(v) || undefined) if not (k == "r") # r = rules, which is not a float...
    )

    return new LSystem({
        iterations :  params.it
        size:         params.l
        sizeGrowth:   params.sg
        angle:        params.a
        angleGrowth:  params.ag
      } ,decodeURIComponent(params.r)
      "unnamed"
    )

  isIsomorphicTo: (system) => @rules == system.rules and @params.iterations == system.params.iterations
