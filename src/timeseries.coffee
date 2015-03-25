
# performs a binary search on values to find the nearest index of the given value
# assumes values is monotonic
getIndex = (values, value) ->
	iMin = 0
	iMax = values.length-1
	vMin = values[iMin]
	vMax = values[iMax]
	if value <= vMin
		return 0
	if value >= vMax
		return values.length-1
	while iMax-iMin > 1
		iMid = Math.round (iMin + iMax)/2
		vMid = values[iMid]
		if vMid > value
			iMax = iMid
			vMax = vMid
		else
			iMin = iMid
			vMin = vMid
	if (value-vMin) > (vMax-value)
		iMax
	else
		iMin


class @TimeseriesChart extends Chart
	constructor: (container, data, opts) ->
		_.defaults opts, {
			timeField: 'time'
			xLabel: 'Time'
			xZoom: 'user'
			yZoom: 'auto'
			cursorColor: '#f00'
			series: []
			xMaxTicks: 6
		}
		super container, opts

		@container.addClass 'timeseries'

		@xFormatter = new TimeFormatter()
		@xAxis.roundingStrategy = 'time'

		@time = _.pluck data, @opts.timeField
		[tMin, mid..., tMax] = @time
		this.xResize tMin, tMax
		this.xClamp()

		yMin = null
		yMax = null
		@data = data
		for s in @opts.series
			ys = _.pluck data, s.yField
			_.defaults s, {
				color: '#000'
				width: 1
				markerSize: 6
			}
			for y in ys
				if !yMin or yMin > y
					yMin = y
				if !yMax or yMax < y
					yMax = y
		this.yResize yMin, yMax
		this.yRound()

		@cursor = $("<div class='cursor'><div class='bar' style='border-left: 1px solid #{opts.cursorColor}'></div><div class='info'></div></div>").appendTo @dataCanvasContainer
		@cursorWidth = @cursor.width()

		this.render()

	renderData: (context) ->
		# filter the data based on the current axis limits
		iMin = getIndex @time, context.xRange.min
		if iMin > 0
			iMin -= 1
		iMax = getIndex @time, context.xRange.max
		if iMax < @data.length-2
			iMax += 1
		plotData = @data[iMin..iMax]
		plotTime = _.pluck plotData, @opts.timeField

		# render the series
		for s in @opts.series
			ys = _.pluck plotData, s.yField
			context.setStroke s.color, s.width
			context.stroke ->
				context.moveTo {x: plotTime[0], y: ys[0]}
				for i in [1..plotData.length-1]
					context.lineTo {x: plotTime[i], y: ys[i]}
			if s.marker and plotData.length < context.width/4
				context.drawMarkers s.marker, s.markerSize, s.color, plotTime, ys

		# update the cursor position
		if @cursor.is ':visible'
			time = parseFloat @cursor.data('time')
			p = {x: time, y: 0}
			context.plotToCanvas p
			@cursor.css 'left', p.x-@cursorWidth/2


	onClick: (p) ->
		@context.canvasToPlot p
		index = getIndex @time, p.x
		value = @data[index]
		time = value[@opts.timeField]
		pCanvas = {x:time, y: 0}
		@context.plotToCanvas pCanvas
		@cursor.css 'left', pCanvas.x-@cursorWidth/2
		@cursor.data 'time', time
		info = @cursor.find '.info'
		info.html('')
		t = @xFormatter.format(@xAxis.span, p.x).replace '|', ' '
		info.append "<div style='color: #{@opts.cursorColor}'>#{t}</div>"
		for s in @opts.series
			info.append "<div style='color: #{s.color}'>#{s.yField}: #{value[s.yField]}</div>"
		@cursor.show()


window.tinyplot = {
	TimeseriesChart: TimeseriesChart
}