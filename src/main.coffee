
class @TimeseriesChart extends Chart
	constructor: (container, data, opts) ->
		_.defaults opts, {
			timeField: 'time'
			xLabel: 'Time'
			xZoom: 'user'
			yZoom: 'auto'
			series: []
		}
		super container, opts

		@xFormatter = new TimeFormatter()

		time = _.pluck data, @opts.timeField
		[tMin, mid..., tMax] = time
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

		this.render()

	renderData: (context) ->
		plotData = _.filter(@data, (d) => t = d[@opts.timeField]; t >= context.xRange.min and t <= context.xRange.max)
		plotTime = _.pluck plotData, @opts.timeField
		for s in @opts.series
			ys = _.pluck plotData, s.yField
			context.setStroke s.color, s.width
			context.stroke ->
				context.moveTo {x: plotTime[0], y: ys[0]}
				for i in [1..plotData.length-1]
					context.lineTo {x: plotTime[i], y: ys[i]}
			if s.marker and plotData.length < context.width/4
				context.drawMarkers s.marker, s.markerSize, s.color, plotTime, ys

window.tinyplot = {
	TimeseriesChart: TimeseriesChart
}