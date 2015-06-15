
# provides a nice upper limit for a number (used in axis sizing)
smartCeil = (v) ->
	log = Math.log10(v)
	divisor = Math.pow(10, (Math.ceil(log)-1))
	n = v / divisor
	while n > 10
		divisor *= 2
		n = v / divisor
	Math.ceil(v / divisor) * divisor


class @StackedBarChart extends Chart
	constructor: (container, data, opts) ->
		_.defaults opts, {
			xField: 'x'
			yField: 'y'
			groupField: 'group'
			opacityField: null
			xLabel: 'x'
			yLabel: 'y'
			yPrefix: ''
			title: 'Title'
			title_class: null
			useDataCanvas: false
			interact: false
			onClick: (value) -> {}
		}
		super container, opts
		@container.addClass 'stacked-bar'

		if @opts.yPrefix == '$'
			@yFormatter = new DollarFormatter()

		xValues = _.pluck data, opts.xField
		xUniq = _.uniq xValues
		unless opts.xOrder
			opts.xOrder = xUniq.sort()
		columnWidth = 100/opts.xOrder.length
		groups = _.uniq(_.pluck(data, opts.groupField))
		unless opts.groupOrder
			opts.groupOrder = groups.sort()

		# populate the x axis
#		for xGroup in opts.xOrder
#			$("<div class='group-label' style='width: #{columnWidth}%'>#{xGroup}</div>").appendTo xAxis
#		$("<div class='axis-label'>#{opts.xLabel}</div>").appendTo xAxis
		@xAxis.setFixedArray opts.xOrder

		# group the data
		yMax = 0
		xGroups = {}
		for xGroup in opts.xOrder
			values = _.filter(data, (v) -> v[opts.xField] == xGroup)
			sum = _.reduce(values
				(memo, v) -> memo + v[opts.yField]
				0)
			yMax = Math.max yMax, sum
			xGroups[xGroup] = {values: values, total: sum}
		this.yResize 0, yMax
		this.yRound()
		yMax = @yAxis.max

		# create the bars
		self = this
		for xGroup in opts.xOrder
			column = $("<div class='column' style='width: #{columnWidth}%'></div>").appendTo @dataCanvasContainer
			y = 0
			for group in opts.groupOrder
				color = opts.groupColors[group]
				values = _.filter(xGroups[xGroup].values, (v) -> v[opts.groupField] == group)
				for value in values
					height = value[opts.yField] / yMax * 100
					opacity = 1
					if opts.opacityField
						opacity = value[opts.opacityField]
					box = $("<a class='box' style='height: #{height}%; bottom: #{y}%; background-color: #{color}; opacity: #{opacity}'></a>").appendTo column
					do(value) ->
						box.click ->
							self.dataCanvasContainer.find('a.box').removeClass('active')
							$(this).addClass('active')
							opts.onClick value
					y += height
			totalString = @yFormatter.format(@yAxis.span, xGroups[xGroup].total)
			$("<div class='total' style='bottom: #{y}%'>#{opts.yPrefix}#{totalString}</div>").appendTo column

		this.render()



# Generates a stacked bar chart
# Arguments:
#   container - the jQuery selector for the chart container
#   data - an array of objects to generate the chart from
#   opts - an object containing optional values
#
# Options:
#   xField: name of the field to group by on the x axis
#   yField: name of the field to plot on the y axis
#   groupField: name of the field to make color groups from
#   groupOrder: the order of the groupField values to arrange in the stack
#   groupColors: an object mapping groups to colors
#   xLabel: label for the x axis
#   yLabel: label for the y axis
#   yPrefix: prefix string for the y values (like '$')
#   title: overall title of the plot
#   onClick: callback function that triggers when a box is clicked
window.tinyplot.StackedBarChart = StackedBarChart