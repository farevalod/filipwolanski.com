titleHeight = 5
descHeight = 5
authorWidth = 2
chartHeight = 15
bookWidth = 2
chartLeftPadding = 7

rem = 16
transitionTime = 1000

writers = []
books = []

win = $ window

processData = ->
  d = window.words
  writers = _.map d.english, (w, key) -> _.extend w,
    author: key
    language: "english"
    expanded: false
  writers = writers.concat _.map d.french, (w,key) -> _.extend w,
    author: key
    language: "french"
    expanded: false
  writers = _.sortBy writers, (w)-> -w['distinct-stem-count']

  _.each writers, (w, i)->
    w.index = i
    writer =
      author: w.author
      language: w.language
      dates: w.dates
    writer['author-distinct-stem-count'] = w['distinct-stem-count']
    writer['author-distinct-token-count'] = w['distinct-token-count']
    writer['author-word-count'] = w['word-count']
    writer['number-of-books'] = w.books.length
    writer['author-density'] = w['distinct-token-count']/w['word-count']
    writer.index = i
    writer.books = _.sortBy writer.books, (w)-> -w['distinct-stem-count']
    books.push.apply books, _.map w.books, (b,i)->
      b['book-index'] = i
      b['density'] =  b['distinct-token-count']/b['word-count']
      _.extend b, writer

  books = _.sortBy books, (w)-> -(w.index + w['book-index']/100)

setupLegend = _.once ->
  d3.select "#legend"
    .append 'g'
    .attr "transform", "translate(0, #{rem})"
    .attr 'class', 'axis'

setupAxis = (scale) ->
  d3.svg.axis()
   .scale scale
   .orient "right"
   .ticks 6

setupScales = ->
  max =  _.max _.pluck writers, 'distinct-stem-count'
  max = 15000
  stem = d3.scale
    .linear()
    .domain [max,0]
    .range [0, chartHeight*rem - 2*rem ]

  max =  _.max _.pluck writers, 'word-count'
  words = d3.scale
    .pow().exponent(0.5)
    .domain [0,max]
    .range [0, authorWidth*rem]

  max =  _.max _.pluck books, 'density'
  density = d3.scale
    .linear()
    .domain [0,max]
    .range [0, 0.8]

  stem:stem
  words:words
  density:density

setupScroll = _.once (positions)->
  new IScroll '.authorsContainer',
    mouseWheel: false
    scrollbars: false
    scrollX: true
    scrollY: false

setupBooks = _.once ->
  bks = d3.select "#authors"
    .selectAll '.book'
    .data books
    .enter()
    .append 'g'
    .attr 'class', 'book'
    .on 'click', (d,i)->
      writers[d.index].expanded = not writers[d.index].expanded
      render withTransitions: true
  bks
    .append 'circle'
    .attr 'class', (d) -> "words #{d.language}"
  bks

setupAuthors = _.once ->
  authors = d3.select "#authors"
    .selectAll '.author'
    .data books
    .enter()
    .append 'g'
    .attr 'class', 'author'
    .on 'click', (d,i)->
      writers[d.index].expanded = not writers[d.index].expanded
      render withTransitions: true
  authors
    .append 'text'
    .attr 'class', 'text'
    .attr 'transform', "translate(#{-0.2*rem},#{0.5*rem})rotate(45)"
  authors
    .append 'line'
    .attr 'class', 'grid'
    .attr 'x1', 0
    .attr 'x2', 0
    .attr 'y1', -rem
    .attr 'y2', -chartHeight*rem + rem
  authors

makeBookPositions = ->
  value = 'distinct-stem-count'
  index = []

  index.push.apply index, _.map _.filter(writers, (w)-> not w.expanded), (w,i)->
    type: "author"
    index: w.index
    value: w[value]

  _.each _.filter(writers, (w)-> w.expanded), (w)->
    b = _.filter books, (b)-> b.index is w.index
    index.push.apply index, _.map b, (b,i)->
      type: "book"
      index: b.index
      bindex: b['book-index']
      value: b[value]
  index = _.sortBy index, (i) -> -i.value

  position = chartLeftPadding*rem
  for idx,i in index
    idx.position = position
    if idx.type is 'author' then position+=(authorWidth*rem) + rem
    else position += (bookWidth*rem) + rem
  index

getBookPosition = (positions, d, i) ->
  unless writers[d.index].expanded
    _.find(positions, (p) -> p.type is 'author' and p.index is d.index).position
  else
    _.find(positions, (p) ->
      p.type is 'book' and p.index is d.index and p.bindex is d['book-index']).position

getBookHeight = (positions, d, i) ->
  unless writers[d.index].expanded
    _.find(positions, (p) -> p.type is 'author' and p.index is d.index).value
  else
     _.find(positions, (p) ->
       p.type is 'book' and p.index is d.index and p.bindex is d['book-index']).value

getBookWidth = (positions, d, i) ->
  unless writers[d.index].expanded then (authorWidth*rem)/d['number-of-books']
  else (bookWidth*rem)

getBookOpacity = (d,i) ->
  unless writers[d.index].expanded then 0.3/d['number-of-books']
  else 0.3

getAuthorY = (positions, d, i) -> chartHeight*rem

getAuthorRotation = (d,i) -> if writers[d.index].expanded then 45 else 45

getAuthorTextDisplay = (d,i) ->
  unless writers[d.index].expanded
    if d['book-index'] is 0 then 'inline' else 'none'
  else 'inline'

getAuthorText = (d,i) ->
  s  = if writers[d.index].expanded
    "<tspan class='title'>#{d['title']}</tspan>&nbsp;&nbsp;"
  else ""
  s += """
  <tspan class="name">#{d['author']}</tspan>
  """
  v = unless writers[d.index].expanded
        "&nbsp;&nbsp; <tspan class='dates'>(#{d.dates[0]}-#{d.dates[1]})</tspan>"
  else ""
  s+v

render = (opts) ->
  wid = $(".wrapper").offset().left
  $('.legendContainer').css marginLeft: wid
  chartLeftPadding = 7 + wid/rem

  positions = makeBookPositions()
  $ '#authors'
    .width _.max(_.pluck positions, 'position') + 3*authorWidth*rem + rem

  scales = setupScales()
  if opts.withLegend
    legend = setupLegend()
    axis = setupAxis scales.stem
    legend.call axis

  scroll = setupScroll positions
  authors = setupAuthors()
  bks = setupBooks()

  scroll.refresh()

  positionFn = _.partial getBookPosition, positions
  heightFn = _.partial getBookHeight, positions
  widthFn = _.partial getBookWidth, positions
  authorYFn = _.partial getAuthorY, positions

  words = bks.selectAll '.words'
  text = authors.selectAll '.text'

  text
    .html getAuthorText
    .style 'display', getAuthorTextDisplay

  if opts.withTransitions
    bks = bks.transition().duration transitionTime
    words = words.transition().duration transitionTime
    authors = authors.transition().duration transitionTime

  bks
    .attr 'transform', (d,i) ->
      "translate(#{positionFn(d,i)},#{(scales.stem(heightFn(d,i)) + rem)})"
    .attr 'opacity', getBookOpacity
  words.attr 'r', (d,i) ->
    if writers[d.index].expanded then scales.words d['word-count']
    else scales.words d['author-word-count']
  authors
    .attr 'transform', (d,i) ->
      "translate(#{positionFn(d,i)},#{authorYFn.call(@,d,i)})"


resize = ->
  w = win.width()
  h = win.height()
  rem = parseFloat $("html").css 'font-size'

  render withLegend: true


win.resize resize
win.load ->
  processData()
  resize()

