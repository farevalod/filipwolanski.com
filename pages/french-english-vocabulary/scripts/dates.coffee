do ($ = jQuery, d3, window, document) ->

  titleHeight = 5
  authorWidth = 1
  chartHeight = 20
  bookWidth = 1
  chartLeftPadding = 0

  rem = 16
  transitionTime = 1000


  win = $ window

  class DateChart

    constructor: ->

      @processData()

      @legendL = @setupLegend "#dateLegendLeft", 'left'
      @legendR = @setupLegend "#dateLegendRight", 'right'
      @legendB = @setupLegend "#dateLegendBottom", 'bottom'

      @axisL = @setupAxis "left"
      @axisR = @setupAxis "right"
      @axisB = @setupAxis "bottom"
      @axisB.tickFormat d3.format 'f'

      @setupScroll '.date-viewport-scroll'
      @setupBooks()


    render: ->

      @scale = @setupScales()

      @axisL.scale @scale.stem
      @axisR.scale @scale.stem
      @axisB.scale @scale.date

      @legendL.call @axisL
      @legendR.call @axisR
      @legendB.call @axisB

      wid = win.width()
      marg = (wid - @width) / 2
      legendMargin = 7
      chartLeftPadding = _.max([legendMargin*rem, marg]) / rem

      bks = @bks
      words = @bks.selectAll '.words'

      $('#left-legend-date').css
        transform: "translateX(#{chartLeftPadding*rem - legendMargin*rem}px)"
      $('#right-legend-date').css
        transform: "translateX(#{-chartLeftPadding*rem + legendMargin*rem}px)"

      bks
        .attr 'transform', (d,i) =>
          "translate(#{@scale.date(d.date)},#{(@scale.stem(d.count) + rem)})"
        .attr 'opacity', 1
      words
        .attr 'r', 3

      $wcp = $ '.date-count-popup'
      $se = $ '#date'
      words.on 'mouseover', (d, i) =>

        text = "#{d.author} &mdash; #{d.title}"
        y = -29.5*rem + @scale.stem(d.count)
        x = @scale.date(d.date) +
            chartLeftPadding*rem - 2.4*rem - @adjustScroll

        $wcp
          .css
            opacity: 1
            transform: "translate(#{x}px,#{y}px)"
          .html text

      words.on 'mouseout', -> $wcp.css opacity: 0

    processData : ->

      points = _.map window.words.books, (b) ->
        lang: b.lang
        title: b.title
        author: b.author
        count: b['limited-distinct']
        date: window.dates[b.title]

      @points = _.filter points, (p) -> p.date isnt undefined

    setupLegend : (sel, dir) ->
      xDisp = if dir is "right" or dir is 'bottom' then 0 else 3
      yDisp = if dir is "bottom" then 0 else 1
      d3.select sel
        .append 'g'
        .attr "transform", "translate(#{xDisp*rem}, #{yDisp*rem})"
        .attr 'class', 'axis'

    setupAxis : (orientation) ->
      d3.svg.axis()
       .orient orientation
       .ticks 6

    setupScales :  ->

      stem: @getCountScale()
      date: @getDateScale()


    getDateScale:  ->
      max =  _.max _.pluck @points, 'date'
      min =  _.min _.pluck @points, 'date'

      delta  = 0.1*(max-min)
      min -= delta
      max += delta
      # max = 1000
      stem = d3.scale
        .linear()
        .domain [min, max]
        .range [0, @width]

    getCountScale:  ->
      max =  _.max _.pluck @points, 'count'
      min =  _.min _.pluck @points, 'count'

      delta  = 0.1*(max-min)
      min -= delta
      max += delta
      # max = 1000
      stem = d3.scale
        .linear()
        .domain [max,min]
        .range [0,  chartHeight*rem - 2*rem]


    setupScroll : (el) ->
      $el = $ el
      clicked = false
      clickX = 0

      $el.on
        'mousemove': (e)->
          clicked && updateScrollPos(e)
        'mousedown': (e) ->
          clicked = true
          clickX = e.pageX
        'mouseup': (e) ->
          clicked = false

      updateScrollPos = (e) ->
        $el.scrollLeft $el.scrollLeft() + (clickX - e.pageX)
        clickX = e.pageX


    setupBooks : ->
      @bks = d3.select "#date"
        .selectAll '.book'
        .data @points
        .enter()
        .append 'g'
        .attr 'class', 'book'
      @bks
        .append 'circle'
        .attr 'class', (d) -> "words #{d.lang}"


    resize : ->
      w = win.width()
      h = win.height()
      rem = parseFloat $("html").css 'font-size'
      @width = $('#date').width()
      @adjustScroll = 0
      if @width < 720
        @adjustScroll = 2.4 * rem
        css =
          width: 720
          marginLeft: 3 * rem
        $('#date').css css
        $('#dateLegendBottom').css css
        @width = 720

      @render()

  win.load ->

    dateChart = new DateChart

    win.resize $.proxy dateChart.resize, dateChart
    dateChart.resize()

