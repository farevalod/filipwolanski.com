titleHeight = 5
descHeight = 5
chartHeight = 0
rem = 16

writers = []

win = $ window

data = $.get "assets/words.json", (d)->
  writers = _.map d.english, (w, key) -> _.extend w,
    author: key
    language: "english"
  writers = writers.concat _.map d.french, (w,key) -> _.extend w,
    author: key
    language: "french"
  writers = _.sortBy writers, (w)-> -w['distinct-stem-count']


setupAxis = _.once ->
  d3.select "#legend"
    .append 'g'
    .attr "transform", "translate(0, #{rem})"
    .attr 'class', 'axis'

setupScroll = _.once ->
  new IScroll '.authorsContainer',
    mouseWheel: false
    scrollbars: true
    scrollX: true
    scrollY: false

render = ->
  legend = setupAxis()
  scroll = setupScroll()

  max =  _.max _.pluck writers, 'distinct-stem-count'
  max = 30000

  invert_scale = d3.scale.linear().domain [max,0]
    .range [0, chartHeight - 2*rem - descHeight*rem]
  axis = d3.svg.axis()
    .scale invert_scale
    .orient "right"
    .ticks 6

  legend.call axis

resize = ->
  w = win.width()
  h = win.height()
  rem = parseFloat $("html").css 'font-size'
  chartHeight = h - titleHeight *rem

  $('#chart').css 'height', chartHeight
  $('#desc').css 'top', h

  data.done render


win.resize resize
win.load resize

