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
  @sensitivities: (input) -> Util.map(Util.merge(Util.merge(Defaults.params(), Defaults._sensitivites()), input), (p,k) -> _.extend(p, {name:k}))
  @_sensitivites: ->
    size: {value: 2.3, growth:2.47}
    angle: {value: 2.4, growth:6}

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
    return base+params+sensitivities+offsets

  merge: (system) ->
    _.extend(@, _.pick(system, 'params', 'offsets', 'sensitivities')) if system

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
        config[k] = parseInt(v) if k == 'i'
    )
    offsets = undefined
    if (config.offsets)
      o = config.offsets.split(',')
      offsets =
        x: parseFloat(o[0])
        y: parseFloat(o[1])
        rot: parseFloat(o[2])

    return new LSystem(params, offsets, sensitivities, decodeURIComponent(config.r), config.i, "unnamed")

  isIsomorphicTo: (system) -> if (!system) then false else @rules == system.rules and @iterations == system.iterations

# =========================================
class CompiledSystem
  constructor: (@system, @elements) ->

# =========================================
class SystemCompiler
  _halt: false
  compilationPromise: null
  lastCompiledSystem: null
  beforeCompile: ->
  afterCompile: ->
  reset: -> @compilationPromise = null; @halt()
  initialise: (system) -> @reset() if not system.isIsomorphicTo(@lastCompiledSystem)
  compile: (system) ->
    if (@compilationPromise) then return @compilationPromise
    Util.log('compiling')
    @beforeCompile()
    CHUNK_SIZE = 100000
    def = $.Deferred().progress(Util.log).done( =>
      Util.log( 'setting lastCompiledSystem to ' + system.iterations)
      @lastCompiledSystem = system
      @afterCompile()
    )
    @compilationPromise = def.promise()
    @_halt = false

    textRules = system.rules.split("\n").map (r) -> (r.replace(/\ /g, '')).split(':')

    ruleMap = Util.toObj(textRules)
    seed = _.keys(ruleMap)[0] #choose first rule as system initialiser

    removeNonInstructions = (expr) -> expr.split('').filter((e) -> true if (Renderer.prototype.definitions[e]))

    # todo: this is absolutely horrifying. Sort it out.
    # note to any bypassers - this used to be a single reduce operation,
    # then I decided to make compilation interruptible (or I'll be crashing people's browsers...)
    # Sigh.
    expandChunk = (levelNum,levelExpr, acc, start, processed, count) =>
      while( processed < count )
        if (@._halt)
          Util.log('rejected')
          def.reject(@lastCompiledSystem)
          return
        else if (levelNum == 0)
          def.resolve(removeNonInstructions(levelExpr))
          return
        remaining = count - processed
        reachesEndOfLevel = remaining >= (levelExpr.length - start)
        if (reachesEndOfLevel) then remaining = levelExpr.length - start
        i = start
        end = start + remaining
        while ( i < end)
          symbol = levelExpr[i]
          acc += ruleMap[symbol] || symbol
          i++
        processed += remaining
        start += remaining
        if (reachesEndOfLevel)
          levelNum--
          levelExpr = acc
          acc = ''
          start = 0

      setTimeout(( -> expandChunk(levelNum,levelExpr,acc,start,0,count)),0)

    expandChunk(system.iterations, seed, '', 0,0,CHUNK_SIZE)
    return @compilationPromise

  halt: -> @_halt = true;

# =========================================
