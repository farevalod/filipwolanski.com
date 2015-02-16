sm = require 'sitemap'
fs = require 'fs'
_ = require 'underscore'
es = require "event-stream"
del = require "del"
marked = require 'marked'
gulp = require 'gulp'
sass = require 'gulp-sass'
coffee = require 'gulp-coffee'
connect = require 'gulp-connect'
jade = require 'gulp-jade'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'
minifyCSS = require 'gulp-minify-css'
order = require "gulp-order"
revall = require "gulp-rev-all"
awspublish = require 'gulp-awspublish'
shell = require 'shelljs'

marked.setOptions
  smartypants: true

dest = "public"
cdn = "cdn"
base = "."

pages = [
  "montreal-realestate"
  "french-english-vocabulary"
]

files =
  jade : ['./index.jade', './error.jade']
  assets : ['./assets/*', './vendor/**', 'favicon.png']
  scripts : [
  ]
  styles : [
    'vendor/normalize.css'
    'vendor/fonts.css'
    'styles/main.sass'
  ]

# create the sitemap
urls = [''].concat(pages).map (v) -> url: if v.length then "/#{v}/" else "/#{v}"
sitemap = sm.createSitemap
  hostname: 'http://filipwolanski.com'
  cacheTime: 600000
  urls: urls

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

gulp.task 'connect:public', ->
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
  if files.scripts.length
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

gulp.task 'sitemap', ['combine:styles', 'combine:scripts', 'clean'], (cb)->
  fs.writeFileSync 'public/sitemap.xml', sitemap.toString()
  cb()

gulp.task 'combine:jade', ['combine:styles', 'combine:scripts'], ->
  gulp.src files.jade, base : base
    .pipe jade
      locals:
        scripts: files.scripts
        styles: files.styles
    .pipe gulp.dest dest

gulp.task 'copy:assets', ['clean'], ->
  gulp
    .src files.assets, base : base
    .pipe gulp.dest dest


gulp.task 'cdn', ['copy:assets','combine:jade', 'sitemap'], ->
    gulp.src "#{dest}/**"
      .pipe revall ignore: ['favicon.png', '.html']
      .pipe gulp.dest cdn

gulp.task 'copy:pages', ['cdn'], (cb) ->
  for page in pages
    dir = "./pages/#{page}"
    shell.exec "make -C #{dir}"
    shell.mv "#{dir}/cdn", "./cdn/#{page}"
  cb()


gulp.task 'publish', ->

  publisher = awspublish.create
    bucket: 'filipwolanski.com'
    region: "us-east-1",
  headers =
    'Cache-Control': 'max-age=315360000, no-transform, public'

  gulp.src "#{cdn}/**"
    .pipe awspublish.gzip()
    .pipe publisher.publish headers
    .pipe publisher.sync()
    .pipe awspublish.reporter()


gulp.task 'default', [
  'watch'
  'coffee'
  'jade'
  'sass'
  'assets'
  'connect:public'
]

gulp.task 'dist', [
  'clean'
  'combine:styles'
  'combine:scripts'
  'combine:jade'
  'copy:assets'
  'sitemap'
  'cdn'
  'copy:pages'
  'connect:cdn'
]
