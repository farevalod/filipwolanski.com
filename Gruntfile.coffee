# sitemap generator
sm = require 'sitemap'
fs = require 'fs'

# list of the pages to be included in the site
pages = ["montreal-realestate"]

files =
  sass : ['styles/*.sass']
  jade : ['index.jade']
  assets : ['assets/*', 'vendor/**', 'favicon.png', 'robots.txt']
  coffee : ['scripts/*.coffee']

for page in pages
  for filetype, list of files
    list.push "#{page}/#{list[0]}"

# create the sitemap
urls = [''].concat(pages).map (v) -> url: if v.length then "/#{v}/" else "/#{v}"
sitemap = sm.createSitemap
  hostname: 'http://filipwolanski.com'
  cacheTime: 600000
  urls: urls

module.exports = (grunt) ->

  grunt.initConfig

    sass:
      dist:
        files: [
          expand: true,
          cwd : 'src'
          src: files.sass,
          dest: 'public',
          ext: '.css'
        ]

    jade:
      dist:
        files: [
          expand: true,
          cwd : 'src'
          src: files.jade,
          dest: 'public',
          ext: '.html'
        ]

    copy:
      dist:
        files:[
          expand:true,
          cwd : 'src'
          src:files.assets
          dest:"public"
        ]

    coffee:
      dist:
        options:
          bare: true
        files:[
          expand:true
          cwd : 'src'
          src: files.coffee
          dest:"public"
          ext: '.js'
        ]

    connect:
      server:
        options:
          port: 9000,
          base: 'public'

    watch:
      sass:
        files: "src/**/*.sass"
        tasks: ["sass:dist"]
      copy:
        files: files.assets
        tasks: ["copy:dist"]
      jade:
        files: "src/**/*.jade"
        tasks: ["jade:dist"]
      coffee:
        files: "src/**/*.coffee"
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
