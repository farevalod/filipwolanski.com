# sitemap generator
sm = require 'sitemap'
fs = require 'fs'
_ = require 'underscore'

# list of the pages to be included in the site
pages = [
  "montreal-realestate"
  # "french-english-vocabulary"
]

files =
  sass : [
    expand: true
    cwd: 'src',
    src: ['styles/main.sass']
    dest: 'public'
    ext: '.css'
  ]
  jade : [
    expand: true,
    cwd : 'src'
    src: ['index.jade']
    dest: 'public',
    ext: '.html'
  ]
  assets :[
    expand:true,
    cwd : 'src'
    src:['assets/*', 'vendor/**', 'favicon.png', 'robots.txt']
    dest:"public"
  ]
  coffee : [
    expand:true
    cwd : 'src'
    src: [ 'scripts/*.coffee' ]
    dest:"public"
    ext: '.js'
  ]

for page in pages
  unless fs.existsSync("src/pages/#{page}") then throw "#{page} doesn't exist"
  for filetype, list of files
    template = _.clone list[0]
    template.cwd = 'src/pages'
    if filetype is 'assets' then template.src = ["#{page}/#{template.src[0]}", "#{page}/#{template.src[1]}"]
    else template.src = ["#{page}/#{template.src[0]}"]
    list.push template

watch = {}
for filetype, list of files
  watch[filetype] = []
  for l in list
      cwd = l.cwd
      for i in l.src
        watch[filetype].push "#{cwd}/#{i}"

# create the sitemap
urls = [''].concat(pages).map (v) -> url: if v.length then "/#{v}/" else "/#{v}"
sitemap = sm.createSitemap
  hostname: 'http://filipwolanski.com'
  cacheTime: 600000
  urls: urls

module.exports = (grunt) ->

  grunt.initConfig

    sass: dist: files: files.sass

    jade: dist: files: files.jade

    copy: dist: files: files.assets

    coffee:
      dist:
        options:
          bare: true
        files: files.coffee

    connect:
      server:
        options:
          port: 9000,
          base: 'public'

    watch:
      sass:
        files: watch.sass
        tasks: ["sass:dist"]
      copy:
        files: watch.assets
        tasks: ["copy:dist"]
      jade:
        files: watch.jade
        tasks: ["jade:dist"]
      coffee:
        files: watch.coffee
        tasks: ["coffee:dist"]

  grunt.loadNpmTasks "grunt-contrib-sass"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-jade"
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-coffee'

  grunt.registerTask "sitemap", "Create the sitemap", ->
    grunt.log.writeln 'Writing the sitemap...'
    fs.writeFile 'public/sitemap.xml', sitemap.toString()

  grunt.registerTask "default", [
      "sass:dist"
      "copy:dist"
      "jade:dist"
      "coffee:dist"
      "sitemap"
      "connect"
      "watch"
    ]
