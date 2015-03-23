

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


# gets the canvas element out of a container and sets the size
initCanvas = (container) ->
	canvasElem = container.find('canvas')[0]
	canvasElem.width = container.width()
	canvasElem.height = container.height()
	canvasElem.getContext('2d')


class @Chart

	constructor: (container, opts) ->
		@container = $(container)
		@container.addClass 'tinyplot-chart'
		@opts = opts

		_.defaults opts, {
			title: 'Chart Title'
			subtitle: ''
			xZoom: 'none'
			yZoom: 'none'
			xLabel: 'x'
			yLabel: 'y'
		}
		@xZoomType = opts.xZoom
		@yZoomType = opts.yZoom

		@xFormatter = new NumberFormatter()
		@yFormatter = new NumberFormatter()

		@titleArea = $('<div class="title-area"></div>').appendTo @container
		$("<div class='title text'>#{opts.title}</div>").appendTo @titleArea
		$("<div class='subtitle text'>#{opts.subtitle}</div>").appendTo @titleArea

		@xAxisCanvasContainer = $('<div class="x-axis"><canvas/></div>').appendTo @container
		@xAxisCanvas = initCanvas(@xAxisCanvasContainer)
		@xAxis = new XAxis 0, 1
		@xAxis.label = @opts.xLabel

		@yAxisCanvasContainer = $('<div class="y-axis"><canvas/></div>').appendTo @container
		@yAxisCanvas = initCanvas(@yAxisCanvasContainer)
		@yAxis = new YAxis 0, 1
		@yAxis.label = @opts.yLabel

		@dataCanvasContainer = $('<div class="data"><canvas/></div>').appendTo @container
		@dataCanvas = initCanvas @dataCanvasContainer

		interact(@dataCanvasContainer[0])
			.draggable(
				inertia: true
				onmove: (evt) =>
					this.pan evt.dx, evt.dy
			)
			.gesturable(
				onmove: (evt) =>
					this.zoom 1+evt.ds
			)

		this.makeContext()

		@container.on 'mousewheel', (evt) =>
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
			@dataCanvasContainer.width()
			@dataCanvasContainer.height()
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

	renderData: (context) -> {}

	render: ->
		startTime = new Date().getTime()
		if @xAxis.dirty
			@xAxis.render @xAxisCanvas, @xFormatter, @xAxisCanvasContainer.width(), @xAxisCanvasContainer.height()
		if @yAxis.dirty
			@yAxis.render @yAxisCanvas, @yFormatter, @yAxisCanvasContainer.width(), @yAxisCanvasContainer.height()
		@context.clear()
		this.renderData @context
		stopTime = new Date().getTime()
		console.log "rendered chart in #{stopTime-startTime}ms"
