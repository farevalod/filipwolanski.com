titleHeight = 5
descHeight = 5
authorWidth = 3
chartHeight = 15
bookWidth = 2
rem = 16
transitionTime = 1000

writers = []
books = []

win = $ window

data = $.get "assets/words.json", (d)->
  writers = _.map d.english, (w, key) -> _.extend w,
    author: key
    language: "english"
    expanded: true
  writers = writers.concat _.map d.french, (w,key) -> _.extend w,
    author: key
    language: "french"
    expanded: true
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
    writer.index = i
    writer.books = _.sortBy writer.books, (w)-> -w['distinct-stem-count']
    books.push.apply books, _.map w.books, (b,i)->
      b['book-index'] = i
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

setupScale = ->
  max =  _.max _.pluck writers, 'distinct-stem-count'
  max = 30000
  d3.scale
    .linear()
    .domain [max,0]
    .range [0, chartHeight*rem - 2*rem ]

setupScroll = _.once (positions)->

  $ '#authors'
    .width _.max(_.pluck positions, 'position') + authorWidth + rem
  new IScroll '.authorsContainer',
    mouseWheel: false
    scrollbars: true
    scrollX: true
    scrollY: false

setupBooks = _.once ->
  d3.select "#authors"
    .selectAll '.book'
    .data books
    .enter()
    .append 'g'
    .attr 'class', 'book'
    .on 'click', (d,i)->
      writers[d.index].expanded = not writers[d.index].expanded
      render withTransitions: true
    .append 'rect'

setupAuthors = _.once ->
  d3.select "#authors"
    .selectAll '.author'
    .data books
    .enter()
    .append 'g'
    .attr 'class', 'author'
    .append 'text'

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

  position = 0
  for idx,i in index
    idx.position = position
    if idx.type is 'author' then position+=(authorWidth*rem) + rem
    else position += (bookWidth*rem) + rem
  index

getBookPosition = (positions, d, i) ->
  unless writers[d.index].expanded
    rectWidth = (authorWidth*rem)/d['number-of-books']
    pos = _.find(positions, (p) -> p.type is 'author' and p.index is d.index).position
    pos + (d['book-index'] *rectWidth )
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

getAuthorX = (positions, d, i) ->
  unless writers[d.index].expanded
    p = _.find(positions, (p) -> p.type is 'author' and p.index is d.index).position
    p + (authorWidth*rem)/2 - rem / 2
  else
    p = _.find(positions, (p) ->
      p.type is 'book' and p.index is d.index and p.bindex is d['book-index']).position
    p + (bookWidth*rem)/2 - rem / 2

getAuthorY = (positions, d, i) ->
  chartHeight*rem

getAuthorRotation = (d,i) -> if writers[d.index].expanded then 45 else 45

getAuthorTextDisplay = (d,i) ->
  unless writers[d.index].expanded
    if d['book-index'] is 0 then 'inline' else 'none'
  else 'inline'

getAuthorText = (d,i) ->
  s  = if writers[d.index].expanded
    "<tspan class='title'>#{d['title']}</tspan>&nbsp;&nbsp;"
  else ""
  s + """
  <tspan class="name">#{d['author']}</tspan>&nbsp;&nbsp;
  <tspan class="dates">(#{d.dates[0]}-#{d.dates[1]})</tspan>
  """

render = (opts) ->

  positions = makeBookPositions()

  scale = setupScale()
  if opts.withLegend
    legend = setupLegend()
    axis = setupAxis scale
    legend.call axis

  scroll = setupScroll positions
  authors = setupAuthors()
  titles = setupBooks()

  positionFn = _.partial getBookPosition, positions
  heightFn = _.partial getBookHeight, positions
  widthFn = _.partial getBookWidth, positions
  authorXFn = _.partial getAuthorX, positions
  authorYFn = _.partial getAuthorY, positions

  titles
    .attr 'class', (d) -> "bar #{d.language} #{d['book-index']}"
  authors
    .html getAuthorText
    .style 'display', getAuthorTextDisplay

  if opts.withTransitions
    titles = titles.transition().duration transitionTime
    authors = authors.transition().duration transitionTime

  titles
    .attr 'transform', (d,i) ->
      "translate(#{positionFn(d,i)},#{(scale(heightFn(d,i)) + rem)})"
    .attr 'height', (d,i) -> (chartHeight*rem - scale(heightFn(d,i)) - 2*rem)
    .attr 'width', widthFn
  authors
    .attr 'transform', (d,i) ->
      "translate(#{authorXFn(d,i)},#{authorYFn.call(@,d,i)})rotate(#{getAuthorRotation(d,i)})"


resize = ->
  w = win.width()
  h = win.height()
  rem = parseFloat $("html").css 'font-size'

  data.done render withLegend: true


win.resize resize
win.load resize

