
class @NumberFormatter
	format: (span, value) ->
		value.toString()

class @DollarFormatter
	format: (span, value) ->
		s = value.toFixed(2)
		if s.endsWith('00')
			value.toString()
		else
			s

class @TimeFormatter
	format: (span, value) ->
		t = moment(value)
		formatString = if span < 10000
			'mm:ss.SS'
		else if span < 3600*1000
			'hh:mm:ss'
		else if span < 3600*1000*24*30
			'MM/DD|hh:mm A'
		else
			'YYYY-MM-DD'
		t.format(formatString)


ONE_MINUTE = 60000
ONE_HOUR = ONE_MINUTE * 60
ONE_DAY = ONE_HOUR * 24

class Axis
	constructor: (min, max) ->
		@dirty = true
		@step = 1
		@clampMax = null
		@clampMin = null
		@tickSize = 8
		@fontSize = 12
		@color = '#444'
		@gridColor = '#ccc'
		@maxTicks = 10
		@label = null
		@roundingStrategy = 'base10'
		this.resize(min, max)

	toString: ->
		"#{@min} to #{@max}, step = #{@step} (clamp at #{@clampMin} to #{@clampMax})"

	makeDirty: ->
		@dirty = true

	resize: (min, max) ->
		@min = min
		@max = max
		@span = max - min
		switch @roundingStrategy
			when 'base10'
				exp = Math.floor(Math.log10(@span)-1)
				@step = Math.pow(10, exp)
			when 'time'
				if @span < 1000
					@step = 100
				else if @span < ONE_MINUTE
					@step = 1000
				else if @span < ONE_HOUR
					@step = ONE_MINUTE
				else if @span < ONE_DAY*3
					@step = ONE_HOUR
				else
					@step = ONE_DAY
			else
				throw "Invalid roundingStrategy: #{@roundingStrategy}"
		while @span/@step > @maxTicks
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

	renderGrid: (canvas, width, height) -> {}


class @XAxis extends Axis
	constructor: (canvas, min, max) ->
		super canvas, min, max
		@labels = null

	setFixedArray: (@labels) ->
		@min = -0.5
		@max = @labels.length-0.5
		@step = 1
		@span = @labels.length

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
		canvas.fillStyle = @color
		i = -1
		while x <= @max
			xActual = Math.ceil((x-@min)*scale)-0.5
			text = if @labels
				if i > -1
					@labels[i]
				else
					''
			else
				formatter.format(@span, x)
			lines = text.split '|'
			yActual = @tickSize + @fontSize
			i += 1
			for line in lines
				canvas.fillText line, xActual, yActual
				yActual += @fontSize
			x += @step

		# draw the label
		canvas.fillText @label, width/2, @tickSize + 3*@fontSize + 2

	renderGrid: (canvas, width, height) ->
		scale = width / @span
		x = Math.floor(@min/@step) * @step
		canvas.strokeStyle = @gridColor
		canvas.beginPath()
		while x <= @max
			xActual = Math.ceil((x-@min)*scale)-0.5
			canvas.moveTo xActual, 0
			canvas.lineTo xActual, height
			x += @step
		canvas.stroke()



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
		canvas.fillStyle = @color
		while y <= @max
			yActual = Math.ceil(height - (y-@min)*scale)-0.5
			canvas.textBaseline = if yActual <= 0
				'top'
			else if yActual >= height-1
				'alphabetic'
			else
				'middle'
			text = formatter.format(@span, y)
			lines = text.split '|'
			for line in lines
				canvas.fillText line, width-@tickSize, yActual
				yActual += @fontSize
			y += @step

		# draw the label
		canvas.textAlign = 'center'
		canvas.translate 0, height/2
		canvas.rotate 3*Math.PI/2
		canvas.fillText @label, 0, 0

	renderGrid: (canvas, width, height) ->
		scale = height / @span
		y = Math.floor(@min/@step) * @step
		canvas.strokeStyle = @gridColor
		canvas.beginPath()
		while y <= @max
			yActual = Math.ceil(height - (y-@min)*scale)-0.5
			canvas.moveTo 0, yActual
			canvas.lineTo width, yActual
			y += @step
		canvas.stroke()


