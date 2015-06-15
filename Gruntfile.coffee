module.exports = (grunt) ->

	# Project configuration
	grunt.initConfig {
		pkg: grunt.file.readJSON('package.json')
		concat: {
			options: {
				separator: ';'
			}
			basic: {
				src: ['src/axes.js',  'src/chart.js', 'src/bar.js', 'src/timeseries.js']
				dest: 'build/<%= pkg.name %>.js'
			}
			extras: {
				src: ['vendor/jquery.mousewheel.js', 'vendor/interact-1.2.4.js', 'vendor/moment-2.9.0.js','vendor/lodash-3.5.0.js', 'src/axes.js',  'src/chart.js', 'src/bar.js', 'src/timeseries.js']
				dest: 'build/<%= pkg.name %>-deps.js'
			}
		}
		uglify: {
			options: {
				banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
			}
			build: {
				files: [
					{
						src: 'build/<%= pkg.name %>.js'
						dest: 'build/<%= pkg.name %>.min.js'
					}
					{
						src: 'build/<%= pkg.name %>-deps.js'
						dest: 'build/<%= pkg.name %>-deps.min.js'
					}
				]
			}
		}
		sass: {
			dist: {
				options: {
					style: 'expanded'
				}
				files: {
					'build/<%= pkg.name %>.css': 'css/<%= pkg.name %>.sass',
				}
			}
		}
		cssmin: {
			options: {
				shorthandCompacting: false,
				roundingPrecision: -1
			}
			target: {
				files: {
					'build/<%= pkg.name %>.min.css': 'build/<%= pkg.name %>.css'
				}
			}
		}
	}

	grunt.loadNpmTasks('grunt-contrib-concat')

	grunt.loadNpmTasks('grunt-contrib-uglify')

	grunt.loadNpmTasks('grunt-contrib-sass')

	grunt.loadNpmTasks('grunt-contrib-cssmin')


	# Default task(s)
	grunt.registerTask('default', ['concat', 'sass', 'uglify', 'cssmin'])

