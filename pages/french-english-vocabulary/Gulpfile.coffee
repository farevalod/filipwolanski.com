gulp = require 'gulp'
sass = require 'gulp-sass'
coffee = require 'gulp-coffee'
connect = require 'gulp-connect'
jade = require 'gulp-jade'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'
minifyCSS = require 'gulp-minify-css'
marked = require 'marked'
es = require "event-stream"
del = require "del"
order = require "gulp-order"
revall = require "gulp-rev-all"

marked.setOptions
  smartypants: true

dest = "public"
cdn = "cdn"
base = "."

page = "french-english-vocabulary"

files =
  jade : './index.jade'
  assets : ['./assets/*', './vendor/**']
  scripts : [
    "vendor/jquery-2.1.1.min.js"
    "vendor/underscore-min.js"
    "vendor/velocity.min.js"
    "vendor/d3.min.js"
    "vendor/d3.layout.cloud.js"
    "vendor/iscroll.js"
    "vendor/sticky.js"

    "scripts/vocabulary.coffee"
    "scripts/stems.coffee"
    "scripts/unique.coffee"

    "assets/words.js"
    "assets/example.js"
    "assets/unique.js"
  ]
  styles : [
    'vendor/normalize.css'
    'vendor/fonts.css'
    'styles/main.sass'
  ]

processScripts = (files) ->
  coffeeFile = /\.coffee$/
  files.coffee = []
  files.js = []
  for script, idx in files.scripts
    if coffeeFile.test script
      files.coffee.push script
      files.scripts[idx] = script.replace coffeeFile, '.js'
    else files.js.push script

processStyles = (files) ->
  sassFile = /\.sass/
  files.sass = []
  files.css = []
  for style, idx in files.styles
    if sassFile.test style
      files.sass.push style
      files.styles[idx] = style.replace sassFile, '.css'
    else files.css.push style


processScripts files
processStyles files

gulp.task 'coffee', () ->
  gulp.src files.coffee, base: base
    .pipe coffee()
    .pipe gulp.dest dest

gulp.task 'sass', () ->
  gulp.src files.sass, base : base
    .pipe sass indentedSyntax: true
    .pipe gulp.dest dest

gulp.task 'assets', () ->
  gulp.src files.assets, base : base
    .pipe gulp.dest dest

gulp.task 'jade', () ->
  gulp.src files.jade, base : base
    .pipe jade
      locals:
        scripts: files.scripts
        styles: files.styles
    .pipe gulp.dest dest


gulp.task 'watch', ->
  gulp.watch files.coffee, ['coffee']
  gulp.watch files.sass, ['sass']
  gulp.watch files.assets, ['assets']
  gulp.watch files.jade, ['jade']

gulp.task 'connect', ->
  connect.server
    root: 'public'
    port: 9000
    livereload: false

gulp.task 'connect:cdn', ->
  connect.server
    root: 'cdn'
    port: 9000
    livereload: false

gulp.task 'clean', (cb) -> del [dest, cdn], cb

gulp.task 'combine:scripts', ['clean'],  ->
  ord = files.scripts
  files.scripts = ['scripts/all.min.js']
  coffee = gulp.src files.coffee, base: base
    .pipe coffee()
  js = gulp.src files.js, base: base
  es.merge js, coffee
    .pipe order ord
    .pipe concat files.scripts[0]
    .pipe uglify
      compress: false
      mangle: false
    .pipe gulp.dest dest

gulp.task 'combine:styles', ['clean'],  ->
  files.styles = ['styles/all.min.css']
  sass = gulp.src files.sass, base: base
    .pipe sass indentedSyntax: true
  css = gulp.src files.css, base: base
  es.merge sass, css
    .pipe concat files.styles[0]
    .pipe minifyCSS()
    .pipe gulp.dest dest

gulp.task 'combine:jade', ['combine:styles', 'combine:scripts'], ->
  gulp.src files.jade, base : base
    .pipe jade
      locals:
        scripts: files.scripts
        styles: files.styles
    .pipe gulp.dest dest

gulp.task 'copy', ['combine:jade'], ->
  gulp
    .src files.assets, base : base
    .pipe gulp.dest dest

gulp.task 'cdn', ['copy'], ->
    gulp.src "#{dest}/**"
      .pipe revall ignore: ['.html', '.jpg', '.png']
      .pipe gulp.dest cdn


gulp.task 'default', [
  'watch'
  'coffee'
  'jade'
  'sass'
  'assets'
  'connect'
]

gulp.task 'dist', [
  'clean'
  'combine:styles'
  'combine:scripts'
  'combine:jade'
  'copy'
  'cdn'
]
