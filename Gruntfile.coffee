module.exports = (grunt) ->

  grunt.initConfig

    sass:
      dist:
        files: [
          expand: true,
          cwd : 'src'
          src: ['styles/*.sass'],
          dest: 'public',
          ext: '.css'
        ]

    jade:
      dist:
        files: [
          expand: true,
          cwd : 'src'
          src: ['*.jade'],
          dest: 'public',
          ext: '.html'
        ]

    copy:
      dist:
        files:[
          expand:true,
          cwd : 'src'
          src:"assets/*",
          dest:"public"
        ]

    connect:
      server:
        options:
          port: 9000,
          base: 'public'

    watch:
      sass:
        files: "src/styles/*.sass"
        tasks: ["sass:dist"]
      copy:
        files: "src/assets/*"
        tasks: ["copy:dist"]
      jade:
        files: "src/*.jade"
        tasks: ["jade:dist"]

  grunt.loadNpmTasks "grunt-contrib-sass"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-jade"
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-copy'

  grunt.registerTask "default", [
      "connect"
      "watch"
    ]
