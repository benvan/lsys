class Param
  constructor:(@name,@value,@growth) ->
  toUrlComponent: -> "p.#{@name}=#{@value},#{@growth}"
  @fromUrlComponent: (x) ->
    if (x||"").indexOf("p.") != 0 then return undefined
    parts = x.split('=')
    name = parts[0].substring(2)
    vars = parts[1].split(',').map((v) -> parseFloat(v))
    return new Param(name,vars[0],vars[1])
  @fromJson: (json) -> new Param(json.name, json.value, json.growth)
  toJson: -> {
    name: @name
    value: @value
    growth: @growth
  }

class LSystem
  generatedElements:null #cache
  params: null
  @defaultParams: () -> Util.map(
    size: {value:1, growth: 0.01}
    angle: {value:1, growth: 0.05}
    , (p,k) -> _.extend(p, {name:k})
  )

  constructor: (params, @rules, @iterations, @name) ->
    settings = Util.merge(LSystem.defaultParams(), params)
    @params = Util.map(settings, (c) -> Param.fromJson(c))

  elements: =>
    @generatedElements || @generate()

  generate: =>
    textRules = @rules.split("\n").map (r) -> (r.replace(/\ /g, '')).split(':')

    ruleMap = {}
    ruleMap[r] = exp for [r,exp] in textRules

    expr = textRules[0][0] #choose first rule as system initialiser

    expr = _.reduce expr.split(""), ((acc, symbol) ->
      acc + (ruleMap[symbol] || symbol)
    ), "" for i in [1..@iterations]

    @generatedElements = expr.split("").filter((e) -> true if (Renderer.prototype.definitions[e]))

  # update yourself to look like system (avoiding regeneration where possible)
  merge: (system) =>
    wasIsomorphic = @isIsomorphicTo(system)
    _.extend(@, {
      rules: system.rules,
      iterations: system.iterations,
      params: system.params
    })
    @generate() if not wasIsomorphic


  # this is not the most efficient of methods... (it's also currently broken - inc{Angle,Length} omitted)
  clone: -> return new LSystem.fromUrl(@toUrl())

  toUrl: -> "#i=#{@iterations}&r=#{encodeURIComponent(@rules)}" + _.reduce(@params, ((acc,v) -> "#{acc}&#{v.toUrlComponent()}"), "")

  @fromUrl: (url = location.hash) ->
    return null if url == ""

    params = {}
    config = {}
    _.each(url.substring(1).split("&").map( (x) -> x.split("=")), ([k,v]) ->
        param = Param.fromUrlComponent("#{k}=#{v}")
        if param then params[param.name] = param.toJson()
        else config[k] = v or (parseInt(v) if k == 'i')
    )

    return new LSystem(params, decodeURIComponent(config.r), config.i, "unnamed")

  isIsomorphicTo: (system) => @rules == system.rules and @iterations == system.iterations

