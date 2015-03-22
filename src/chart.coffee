
class Axis
	constructor: (@canvas, min, max) ->
		@dirty = true
		@step = 1
		@clampMax = null
		@clampMin = null
		this.resize(min, max)

	toString: ->
		"#{@min} to #{@max}, step = #{@step} (clamp at #{@clampMin} to #{@clampMax})"

	makeDirty: ->
		@dirty = true

	resize: (min, max) ->
		@min = min
		@max = max
		@span = max - min
		exp = Math.floor(Math.log10(@span)-1)
		@step = Math.pow(10, exp)
		while @span/@step > 10
			@step *= 2

	zoom: (factor) ->
		avg = (@max + @min) / 2
		newSpan = @span / factor
		if @clampMin and @clampMax and newSpan > (@clampMax - @clampMin)
			@min = @clampMin
			@max = @clampMax
			@span = @clampMax - @clampMin
		else
			@min = avg - newSpan/2
			@max = avg + newSpan / 2
			@span = newSpan
		@dirty = true

	pan: (delta) ->
		if delta < 0
			if !@clampMax or @clampMax > @max
				@max = Math.min(@clampMax, @max - delta)
				@min = @max - @span
		else # delta > 0
			if !@clampMin or @clampMin < @min
				@min = Math.max(@clampMin, @min - delta)
				@max = @min + @span
		@dirty = true

	round: ->
		this.resize Math.floor(@min / @step)*@step, Math.ceil(@max / @step)*@step

	clamp: ->
		@clampMin = @min
		@clampMax = @max

	render: ->
		@dirty = false

class XAxis extends Axis
	constructor: (canvas, min, max) ->
		super canvas, min, max

class YAxis extends Axis
	constructor: (canvas, min, max) ->
		super canvas, min, max


# Wrap all canvas methods so we can do scaling and such
class RenderContext
	constructor: (@canvas, @width, @height, @xRange, @yRange) -> {}

	clear: ->
		@canvas.clearRect 0, 0, @width, @height

	setStroke: (style, width) ->
		@canvas.strokeStyle = style
		@canvas.lineWidth = width

	stroke: (cb) ->
		@canvas.beginPath()
		cb()
		@canvas.stroke()

	plotToCanvas: (p) =>
		p.x = (p.x - @xRange.min) / @xRange.span * @width
		p.y = (1 - (p.y - @yRange.min) / @yRange.span) * @height

	moveTo: (p) =>
		this.plotToCanvas p
		@canvas.moveTo p.x, p.y

	lineTo : (p) =>
		this.plotToCanvas p
		@canvas.lineTo p.x, p.y



class @Chart

	constructor: (container, opts) ->
		@container = $(container)
		@container.addClass 'tinyplot-chart'
		@onRender = (context) -> {}

		_.defaults opts, {
			title: 'Chart Title'
			xZoom: 'none'
			yZoom: 'none'
		}
		@xZoomType = opts.xZoom
		@yZoomType = opts.yZoom

		@titleArea = $('<div class="title-area"></div>').appendTo @container
		$("<div class='title text'>#{opts.title}</div>").appendTo @titleArea

		@xAxisCanvasElem = $('<canvas class="x-axis"></canvas>').appendTo @container
		@xAxis = new XAxis @xAxisCanvasElem[0].getContext('2d'), 0, 1

		@yAxisCanvasElem = $('<canvas class="y-axis"></canvas>').appendTo @container
		@yAxis = new YAxis @yAxisCanvasElem[0].getContext('2d'), 0, 1

		@dataCanvasElem = $('<canvas class="data"></canvas>').appendTo @container
		@dataCanvas = @dataCanvasElem[0].getContext('2d')

		@dataCanvasElem[0].width = @dataCanvasElem.width()
		@dataCanvasElem[0].height = @dataCanvasElem.height()

		interact(@dataCanvasElem[0])
			.draggable(
				inertia: true
				onmove: (evt) =>
					this.pan evt.dx, evt.dy
			)

		this.makeContext()

		@container.on 'mousewheel', (evt) =>
#			console.log evt.deltaX, evt.deltaY, evt.deltaFactor
			this.zoom(1 + evt.deltaY / 1000)
			evt.preventDefault()

	xResize: (min, max) ->
		@xAxis.resize min, max
		console.log "xAxis: #{@xAxis.toString()}"
		@xAxis.makeDirty()

	xRound: ->
		@xAxis.round()
		console.log "xAxis: #{@xAxis.toString()}"

	xClamp: ->
		@xAxis.clamp()

	yResize: (min, max) ->
		@yAxis.resize min, max
		console.log "yAxis: #{@yAxis.toString()}"
		@yAxis.makeDirty()

	yRound: ->
		@yAxis.round()
		console.log "yAxis: #{@yAxis.toString()}"

	yClamp: ->
		@yAxis.clamp()

	makeContext: ->
		@context = new RenderContext(
			@dataCanvas
			@dataCanvasElem.width()
			@dataCanvasElem.height()
			@xAxis
			@yAxis
		)

	zoom: (delta) ->
		hasZoomed = false
		if @xZoomType == 'user'
			@xAxis.zoom delta
			hasZoomed = true
		if @yZoomType == 'user'
			@yAxis.zoom delta
			hasZoomed = true
		if hasZoomed
			this.render()

	pan: (dx, dy) ->
		hasPanned = false
		if @xZoomType == 'user'
			@xAxis.pan dx / @context.width * @xAxis.span
			hasPanned = true
		if @yZoomType == 'user'
			@yAxis.pan dy / @context.height * @yAxis.span
			hasPanned = true
		if hasPanned
			this.render()


	render: ->
		startTime = new Date().getTime()
		if @xAxis.dirty
			@xAxis.render()
		if @yAxis.dirty
			@yAxis.render()
		@context.clear()
		@onRender @context
		stopTime = new Date().getTime()
		console.log "rendered chart in #{stopTime-startTime}ms"
