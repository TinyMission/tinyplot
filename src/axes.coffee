
class @NumberFormatter
	format: (span, value) ->
		value.toString()

class @TimeFormatter
	format: (span, value) ->
		t = moment(value)
		formatString = if span < 10000
			'mm:ss.SS'
		else if span < 3600*1000
			'hh:mm:ss'
		else if span < 3600*1000*72
			'MM/DD hh:mm A'
		else
			'YYYY-MM-DD'
		t.format(formatString)


class Axis
	constructor: (min, max) ->
		@dirty = true
		@step = 1
		@clampMax = null
		@clampMin = null
		@tickSize = 8
		@fontSize = 12
		@color = '#444'
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
			min = avg - newSpan/2
			max = avg + newSpan / 2
			this.resize min, max
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

	render: (canvas, formatter, width, height) ->
		canvas.clearRect 0, 0, width, height
		@dirty = false


class @XAxis extends Axis
	constructor: (canvas, min, max) ->
		super canvas, min, max

	render: (canvas, formatter, width, height) ->
		super canvas, formatter, width, height
		scale = width / @span

		# draw the ticks
		x = Math.floor(@min/@step) * @step
		canvas.strokeStyle = @color
		canvas.beginPath()
		while x <= @max
			xActual = Math.ceil((x-@min)*scale)-0.5
			canvas.moveTo xActual, 0
			canvas.lineTo xActual, @tickSize
			x += @step
		canvas.stroke()

		# draw the tick labels
		x = Math.floor(@min/@step) * @step
		canvas.font = "#{@fontSize}px sans-serif"
		canvas.textAlign = 'center'
		while x <= @max
			xActual = Math.ceil((x-@min)*scale)-0.5
			text = formatter.format(@span, x)
			canvas.fillText text, xActual, @tickSize + @fontSize
			x += @step



class @YAxis extends Axis
	constructor: (canvas, min, max) ->
		super canvas, min, max

	render: (canvas, formatter, width, height) ->
		super canvas, formatter, width, height
		scale = height / @span

		# draw the ticks
		y = Math.floor(@min/@step) * @step
		canvas.strokeStyle = @color
		canvas.beginPath()
		while y <= @max
			yActual = Math.ceil(height - (y-@min)*scale)-0.5
			if yActual < 0
				yActual = 0.5
			canvas.moveTo width-@tickSize, yActual
			canvas.lineTo width, yActual
			y += @step
		canvas.stroke()

		# draw the tick labels
		y = Math.floor(@min/@step) * @step
		canvas.font = "#{@fontSize}px sans-serif"
		canvas.textAlign = 'right'
		while y <= @max
			yActual = Math.ceil(height - (y-@min)*scale)-0.5
			canvas.textBaseline = if yActual <= 0
				'top'
			else if yActual >= height-1
				'alphabetic'
			else
				'middle'
			text = formatter.format(@span, y)
			canvas.fillText text, width-@tickSize-3, yActual
			y += @step


