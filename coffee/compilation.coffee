NullSystem = new LSystem({},{},{},0,"","",1,"no system")
DefaultSystem = new LSystem(
  { size: {value: 20}, angle: {value: 9840} },
  { x: 0, y: 50, rot: 0},
  null,
  "L : SS\nS : F-[F-Y[S>(L]]\nY : [-|F-F+)Y]"
  12,
  0.218,
  [ "black", "white", "cyan", "#e8cc00", "#007272", "#ff4c00" ],
  false,
  "return {\n
    angle: t/100,\n
    angleG: t/100,\n
    size: null,\n
    sizeG: null,\n
    offsetX: null,\n
    offsetY: null,\n
    rotation: null\n
  }",
  "click-and-drag-me!"
)

# =========================================
class CompiledSystem
  constructor: (@system, @elements) ->

# =========================================
class SystemCompiler
  _halt: false

  halt: -> @_halt = true;

  compile: (system) ->
    @_halt = false
    CHUNK_SIZE = 400000
    def = $.Deferred()
    def.notify(0) # zero progress

    textRules = system.rules.split("\n").map (r) -> (r.replace(/\ /g, '')).split(':')

    ruleMap = Util.toObj(textRules)
    seed = textRules[0][0] #choose first rule as system initialiser

    removeNonInstructions = (expr) -> expr.split('').filter((e) -> true if (Renderer.prototype.definitions[e]))



    # todo: this is absolutely horrifying. Sort it out.
    # note to any bypassers - this used to be a single reduce operation,
    # then I decided to make compilation interruptible (or I'll be crashing people's browsers...)
    # Sigh.
    expandChunk = (levelNum,levelExpr, acc, start, processed, count) =>
      while( processed < count )
        if (@._halt)
          def.reject()
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

      def.notify((system.iterations - levelNum) / system.iterations)
      setTimeout(( -> expandChunk(levelNum,levelExpr,acc,start,0,count)),0)

    expandChunk(system.iterations, seed, '', 0,0,CHUNK_SIZE)
    return def.promise()

# =========================================
class SystemManager
  compiler: new SystemCompiler
  stagedSystem: null # system pending compilation (replaces active when compiled)
  activeSystem: NullSystem
  compiledElements: null

  activate: (system) ->
    if (@promise and @stagedSystem?.isIsomorphicTo(system))
      @activeSystem.merge(system)
      @promise
    else if (@promise?.state() == 'pending')
      @compiler.halt()
      @promise.fail( => @_recompile(system))
    else @_recompile(system)


  _recompile: (system) ->
    @stagedSystem = system
    @promise = @compiler.compile(system)
    @promise.fail( => @stagedSystem = @activeSystem )
    @promise.pipe( (elements)  =>
      @activeSystem = system
      @compiledElements = elements
      return elements
    )

  getInstructions: -> @compiledElements
