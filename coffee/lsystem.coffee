class Param
  @urlPrefix: "p"
  constructor:(@name,@value,@growth) ->
  toUrlComponent: -> "#{@constructor.urlPrefix}.#{@name}=#{@value},#{@growth}"
  @fromUrlComponent: (x) ->
    if (x||"").indexOf("#{@urlPrefix}.") != 0 then return undefined
    parts = x.split('=')
    name = parts[0].substring(2)
    vars = parts[1].split(',').map((v) -> parseFloat(v))
    return new @(name,vars[0],vars[1])
  @fromJson: (json) -> new @(json.name, json.value, json.growth)
  toJson: -> {
    name: @name
    value: @value
    growth: @growth
  }
  clone: -> Param.fromJson(@.toJson())

class Sensitivity extends Param
  @urlPrefix: "s"
  constructor:(@name,@value,@growth) ->

# =========================================
class Defaults
  @offsets: (input) -> Util.merge({
    x: 0
    y: 0
    rot: 0
  }, input)
  @params: (input) -> Util.map(Util.merge(Defaults._params(), input), (p,k) -> _.extend(p, {name:k}))
  @_params: ->
    size: {value:1, growth: 0.01}
    angle: {value:1, growth: 0.05}
  @sensitivities: (input) -> Util.map(Util.merge(Util.merge(Util.map(Defaults.params(),@_constrain(0,10)), Defaults._sensitivites()), input), (p,k) -> _.extend(p, {name:k}))
  @_constrain: (min,max) -> (val) -> Math.max(min,Math.min(max,val))
  @_sensitivites: ->
    size: {value: 7.7, growth:7.53}
    angle: {value: 7.6, growth:4}

# =========================================
class LSystem
  constructor: (params, offsets, sensitivities, @rules, @iterations, @name) ->
    @params = Util.map(Defaults.params(params), (c) -> Param.fromJson(c))
    @offsets = Defaults.offsets(offsets)
    @sensitivities = Util.map(Defaults.sensitivities(sensitivities), (s) -> Sensitivity.fromJson(s))

  # this is not the most efficient of methods...
  clone: -> return LSystem.fromUrl(@toUrl())

  toUrl: ->
    base = "#?i=#{@iterations}&r=#{encodeURIComponent(@rules)}"
    mkQueryString = (params) -> _.reduce(params, ((acc,v) -> "#{acc}&#{v.toUrlComponent()}"), "")
    params = mkQueryString(@params)
    sensitivities = mkQueryString(@sensitivities)
    offsets = "&offsets=#{@offsets.x},#{@offsets.y},#{@offsets.rot}"
    name = "&name=#{encodeURIComponent(@name)}"
    return base+params+sensitivities+offsets+name

  merge: (system) ->
    _.extend(@, system) if system

  @fromUrl: (url = location.hash) ->
    return null if url == ""

    params = {}
    sensitivities = {}
    config = {}
    _.each(url.substring(2).split("&").map( (x) -> x.split("=")), ([k,v]) ->
        param = Param.fromUrlComponent("#{k}=#{v}")
        sensitivity = Sensitivity.fromUrlComponent("#{k}=#{v}")
        if param then params[param.name] = param.toJson()
        else if sensitivity then sensitivities[sensitivity.name] = sensitivity.toJson()
        else config[k] = v
        config[k] = (parseInt(v) or 0) if k == 'i'
    )
    offsets = undefined
    if (config.offsets)
      o = config.offsets.split(',')
      offsets =
        x: parseFloat(o[0])
        y: parseFloat(o[1])
        rot: parseFloat(o[2])

    return new LSystem(params, offsets, sensitivities, decodeURIComponent(config.r), config.i, decodeURIComponent(config.name) or "unnamed")

  isIsomorphicTo: (system) -> if (!system) then false else @rules == system.rules and @iterations == system.iterations


# =========================================
