
class Axis
	constructor: (min, max) ->
		@dirty = true
		@step = 1
		@clampMax = null
		@clampMin = null
		@tickSize = 12
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

	render: (canvas, width, height) ->
		canvas.clearRect 0, 0, width, height
		@dirty = false


class @XAxis extends Axis
	constructor: (canvas, min, max) ->
		super canvas, min, max

	render: (canvas, width, height) ->
		super canvas, width, height
		scale = width / @span
		x = Math.floor(@min/@step) * @step
		canvas.strokeStyle = @color
		canvas.beginPath()
		while x <= @max
			xActual = Math.ceil((x-@min)*scale)-0.5
			console.log "x tick at #{x} (#{xActual})"
			canvas.moveTo xActual, 0
			canvas.lineTo xActual, @tickSize
			x += @step
		canvas.stroke()


class @YAxis extends Axis
	constructor: (canvas, min, max) ->
		super canvas, min, max

	render: (canvas, width, height) ->
		super canvas, width, height
		scale = height / @span
		y = Math.floor(@min/@step) * @step
		canvas.strokeStyle = @color
		canvas.beginPath()
		while y <= @max
			yActual = Math.ceil(height - (y-@min)*scale)-0.5
			console.log "y tick at #{y} (#{yActual})"
			canvas.moveTo width-@tickSize, yActual
			canvas.lineTo width, yActual
			y += @step
		canvas.stroke()

