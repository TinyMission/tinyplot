
timeseries = (container, data, opts) ->
	_.defaults opts, {
		timeField: 'time'
		xLabel: 'time'
		yLabel: 'y'
		xZoom: 'user'
		yZoom: 'auto'
		series: []
	}
	chart = new Chart(container, opts)

	time = _.pluck data, opts.timeField
	[tMin, mid..., tMax] = time
	chart.xResize tMin, tMax
	chart.xClamp()

	yMin = null
	yMax = null
	for s in opts.series
		ys = _.pluck data, s.yField
		_.defaults s, {
			color: '#000'
			width: 1
		}
		for y in ys
			if !yMin or yMin > y
				yMin = y
			if !yMax or yMax < y
				yMax = y
	chart.yResize yMin, yMax
	chart.yRound()

	chart.onRender = (context) ->
		plotData = _.filter(data, (d) -> t = d[opts.timeField]; t >= context.xRange.min and t <= context.xRange.max)
		plotTime = _.pluck plotData, opts.timeField
		for s in opts.series
			ys = _.pluck plotData, s.yField
			context.setStroke s.color, s.width
			context.stroke ->
				context.moveTo {x: plotTime[0], y: ys[0]}
				for i in [1..plotData.length-1]
					context.lineTo {x: plotTime[i], y: ys[i]}

	chart.render()


window.tinyplot = {
	timeseries: timeseries
}