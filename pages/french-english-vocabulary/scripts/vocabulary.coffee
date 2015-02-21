do ($ = jQuery, d3, window, document) ->

  titleHeight = 5
  authorWidth = 2
  chartHeight = 20
  bookWidth = 2
  chartLeftPadding = 0

  rem = 16
  transitionTime = 1000


  win = $ window

  class VocabularyChart

    constructor: ->

      @writersExpanded = false

      @processData()

      @legendL = @setupLegend "#wordLegendLeft", 'left'
      @legendR = @setupLegend "#wordLegendRight", 'right'
      @axisL = @setupAxis "left"
      @axisR = @setupAxis "right"

      @setupScroll '.viewport-scroll'
      @setupBooks()
      @setupAuthors()


    render: (opts) ->

      data = if @writersExpanded then @books else @writers
      wid = win.width()
      marg = (wid - ((data.length - 1 ) * ((authorWidth * rem) + rem)) ) / 2
      legendMargin = 7
      chartLeftPadding = _.max([legendMargin*rem, marg]) / rem

      positions = @calculatePositions 'limited-distinct'
      maxPosition = _.max(_.pluck positions, 'position')
      $('.scroller').width maxPosition + 3*authorWidth*rem + rem

      scales = @setupScales @writersExpanded
      @axisL.scale scales.stem
      @axisR.scale scales.stem

      positionFn = _.bind @getBookPosition, @, positions
      heightFn = _.bind @getBookHeight, @, positions
      widthFn = _.bind @getBookWidth, @, positions
      authorYFn = _.bind @getAuthorY, @, positions

      words = @bks.selectAll '.words'
      text = @authors.selectAll '.text'

      @getAuthorText text
      text
        .style 'display', $.proxy @getAuthorTextDisplay, @


      if opts.withTransitions
        bks = @bks.transition().duration transitionTime
        words = words.transition().duration transitionTime
        authors = @authors.transition().duration transitionTime

        @legendL.transition().duration(transitionTime).call @axisL
        @legendR.transition().duration(transitionTime).call @axisR

        $('.scroller').velocity 'scroll',
          axis: 'x'
          offset: '0'
          container: $ '.viewport-scroll'

        $('#left-legend').velocity
          p:
            translateZ: 0
            translateX: (chartLeftPadding - legendMargin)*rem
          o:
            easing: "ease-out"
            duration: transitionTime
        $('#right-legend').velocity
          p:
            translateZ: 0
            translateX: (-chartLeftPadding + legendMargin)*rem
          o:
            easing: "ease-out"
            duration: transitionTime

      else
        @legendL.call @axisL
        @legendR.call @axisR
        bks = @bks
        authors = @authors
        $('#left-legend').css
          transform: "translateX(#{chartLeftPadding*rem - legendMargin*rem}px)"
        $('#right-legend').css
          transform: "translateX(#{-chartLeftPadding*rem + legendMargin*rem}px)"

      bks
        .attr 'transform', (d,i) =>
          "translate(#{positionFn(d,i)},#{(scales.stem(heightFn(d,i)) + rem)})"
        .attr 'opacity', $.proxy @getBookOpacity, @
      words
        .attr 'r', (d,i) =>
          if @writersExpanded then scales.words d['count']
          else scales.words d['author-count']
      authors
        .attr 'transform', (d,i) =>
          "translate(#{positionFn(d,i)},#{authorYFn(d,i)})"

      $wcp = $ '.word-count-popup'
      @bks.selectAll('.words').on 'mouseover', ((d, i) =>
        text = if @writersExpanded then d['limited-distinct']
        else d['author-limited-distinct']

        radius = if @writersExpanded then scales.words d['count']
        else scales.words d['author-count']

        y = -39.7*rem + scales.stem(heightFn(d,i)) - radius
        x = positionFn(d,i) - authorWidth*rem  - 0.4*rem

        $wcp
          .css
            opacity: 1
            transform: "translate(#{x}px,#{y}px)"
          .html text)
        .on 'mouseout', -> $wcp.css opacity: 0

    processData : ->

      d = window.words

      @writers = @processWriters d.authors
      @books = @processBooks @writers, d.books

    processBooks: (writers, data) ->

      books = []

      _.each writers, (w, i)->
        writer =
          author: w.author
          lang: w.lang
          dates: w.dates
        writer['author-limited-count'] = w['limited-count']
        writer['author-limited-distinct'] = w['limited-distinct']
        writer['author-distinct'] = w['distinct']
        writer['author-count'] = w['count']

        bks = _.filter data, (b) -> b.author is w.author
        writer['number-of-books'] = bks.length
        writer.index = i
        writer.books = _.sortBy bks, (w)-> -w['limited-distinct']
        books.push.apply books, _.map writer.books, (b,i)->
          b['book-index'] = i
          _.extend b, writer

      _.sortBy books, (w)-> -(w.index + w['book-index']/100)


    processWriters: (data) ->
      writers = _.sortBy data, (w) -> -w['limited-distinct']
      writers.map (w, index) ->
        _.extend w,
          index: index
          dates: [w.born, w.died]

    setupLegend : (sel, dir) ->
      xDisp = if dir is "right" then 0 else 3
      d3.select sel
        .append 'g'
        .attr "transform", "translate(#{xDisp*rem}, #{rem})"
        .attr 'class', 'axis'

    setupAxis : (orientation) ->
      d3.svg.axis()
       .orient orientation
       .ticks 6

    setupScales : _.memoize (writersExpanded) ->

      if writersExpanded then all = @books
      else all = @writers

      stem: @getStemScale all
      words: @getWordScale all

    getWordScale: (all) ->
      max =  _.max _.pluck all, 'count'
      words = d3.scale
        .pow().exponent(0.5)
        .domain [0,max]
        .range [0, authorWidth*rem]

    getStemScale: (all) ->
      max =  _.max _.pluck all, 'limited-distinct'
      min =  _.min _.pluck all, 'limited-distinct'

      delta  = 0.2*(max-min)
      min -= delta
      max += delta
      # max = 1000
      stem = d3.scale
        .linear()
        .domain [max,min]
        .range [0, chartHeight*rem - 2*rem ]


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
      @bks = d3.select "#authors"
        .selectAll '.book'
        .data @books
        .enter()
        .append 'g'
        .attr 'class', 'book'
      @bks
        .append 'circle'
        .attr 'class', (d) -> "words #{d.lang}"

    setupAuthors : ->
      @authors = d3.select "#authors"
        .selectAll '.author'
        .data @books
        .enter()
        .append 'g'
        .attr 'class', 'author'
      @authors
        .append 'text'
        .attr 'class', 'text'
        .attr 'transform', "translate(#{-0.2*rem},#{0.5*rem})rotate(45)"
      @authors
        .append 'line'
        .attr 'class', 'grid'
        .attr 'x1', 0
        .attr 'x2', 0
        .attr 'y1', -rem
        .attr 'y2', -chartHeight*rem + rem

    calculatePositions : (value) ->
      index = []

      if @writersExpanded
        _.each @writers, (w) =>
          b = _.filter @books, (b)-> b.index is w.index
          index.push.apply index, _.map b, (b,i)->
            type: "book"
            index: b.index
            bindex: b['book-index']
            value: b[value]
      else
        index.push.apply index, _.map @writers, (w,i) ->
          type: "author"
          index: w.index
          value: w[value]

      index = _.sortBy index, (i) -> -i.value

      position = chartLeftPadding*rem
      for idx,i in index
        idx.position = position
        if idx.type is 'author' then position+=(authorWidth*rem) + rem
        else position += (bookWidth*rem) + rem

      return index

    getBookPosition : (positions, d, i) ->
      unless @writersExpanded
        _.find(positions, (p) ->
          p.type is 'author' and p.index is d.index).position
      else
        _.find(positions, (p) ->
          p.type is 'book' and p.index is d.index and p.bindex is d['book-index']).position

    getBookHeight : (positions, d, i) ->
      unless @writersExpanded
        _.find(positions, (p) -> p.type is 'author' and p.index is d.index).value
      else
         _.find(positions, (p) ->
           p.type is 'book' and p.index is d.index and p.bindex is d['book-index']).value

    getBookWidth : (positions, d, i) ->
      unless @writersExpanded then (authorWidth*rem)/d['number-of-books']
      else (bookWidth*rem)

    getBookOpacity : (d,i) ->
      unless @writersExpanded then 0.5/d['number-of-books']
      else 0.5

    getAuthorY : (positions, d, i) -> chartHeight*rem

    getAuthorRotation : (d,i) -> if @writersExpanded then 45 else 45

    getAuthorTextDisplay : (d,i) ->
      unless @writersExpanded
        if d['book-index'] is 0 then 'inline' else 'none'
      else 'inline'

    getAuthorText : (del) ->

      del.selectAll('tspan').remove()

      del.append 'tspan'
        .attr 'class', 'title'
        .text (d, i) =>
          if @writersExpanded then "#{d['title']}   "
          else  ""

      del.append 'tspan'
        .attr 'class', 'name'
        .text (d, i) => """
            #{d['author']}
          """

      del.append 'tspan'
        .attr 'class', 'dates'
        .text (d, i) =>
          unless @writersExpanded then "   (#{d.dates[0]}-#{d.dates[1]})"
          else  ""

    toggleExpanded: ->
      @writersExpanded = !@writersExpanded
      @render withTransitions: true

    resize : ->
      w = win.width()
      h = win.height()
      rem = parseFloat $("html").css 'font-size'

      @render withTransitions: false

  win.load ->

    vocabularyChart = new VocabularyChart

    currentAction = 'writers'

    filterEls = $ '.chart-filter .filter'
    filterEls.on 'click', (ev) ->
      ct = $ ev.currentTarget
      action = ct.attr 'data-id'
      if action is currentAction then return

      currentAction = action
      $('.chart-filter .filter').removeClass 'active'
      ct.addClass 'active'

      $('#chart').removeClass().addClass action

      vocabularyChart.toggleExpanded()

      window.setTimeout ->
        $(document.body).trigger "sticky_kit:recalc"
      , transitionTime


    win.resize $.proxy vocabularyChart.resize, vocabularyChart
    vocabularyChart.resize()

