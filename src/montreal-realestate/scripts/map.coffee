findThreshold = (list, size) ->
  sorted = list.sort (a,b) -> parseFloat(a)-parseFloat(b)
  interval = Math.ceil sorted.length/size
  sorted[x] for x in [interval..interval*(size-1)] by interval

createColors = (data, feature, cols) ->
  points =  _.map data.features, (f)-> feature f
  withoutZeros = _.reject points, (p)-> p is 0
  threshold = findThreshold withoutZeros, cols.length
  d3.scale.threshold()
    .domain threshold
    .range cols

redrawSVG = ->
  bottomLeft = project(bounds[0])
  topRight = project(bounds[1])

  svg.attr("width", topRight[0] - bottomLeft[0])
    .attr("height", bottomLeft[1] - topRight[1])
    .style("margin-left", bottomLeft[0] + "px")
    .style("margin-top", topRight[1] + "px")

  svg.selectAll("g").attr("transform", "translate(" + -bottomLeft[0] + "," + -topRight[1] + ")")
  svg.selectAll("path").attr("d", path)

# leaflet defines the d3 geographic projection
project = (x) ->
  point = map.latLngToLayerPoint(new L.LatLng(x[1], x[0]))
  [point.x, point.y]

drawPopover = (opt, d) ->
  price = parseFloat d.properties.avg_price
  y = (mouse.y + mouse.scrollTop + 50 ) + 'px'
  x = (mouse.x - 100) + 'px'
  $("#popover").css 'transform': "translate(#{x},#{y})"
  $("#popover .title").text d.properties.CSDNAME
  $("#popover .subtitle").text "Census #" + d.properties.DAUID

  if opt.feature(d)
    $("#dataTitle").text opt.title
    $("#dataValue").text valToString opt.feature(d), opt.format
    if _.isFunction opt.count_feature
      $('.data-hide-field').show()
      $("#dataPoints").text opt.count_feature(d)
    else
      $('.data-hide-field').hide()
    $("#popover .body").show()
    $("#popover .empty").hide()
  else
    $("#popover .body").hide()
    $("#popover .empty").show()

colorMap = (opt) ->
  colors = createColors data, opt.feature, opt.colors
  createLegend colors, opt, d3.extent _.map data.features, (f)-> opt.feature f
  d3.selectAll "path"
    # .attr "class", (d) ->
    #   price = opt.feature d
    #   if price  > 0
    #     idx = opt.colors.indexOf colors(price)
    #     "highlight-#{idx} highligh-map land"
    #   else  ""
    .style "fill", (d)->
      price = opt.feature d
      if price  > 0 then colors price else "#ffffff"
    .style "opacity", (d) ->
      price = opt.feature d
      if price  > 0 then 0.5 else 0

renderDataOption = (opt) ->
  colorMap opt
  d3.selectAll("path").on "mousemove", _.partial drawPopover, opt
  $('#legendSVG').show()
  $('.spinner').hide()

selected_opts = ['house', 'town', 'condo']
selected_data = 'data_points'

createLegend = (colors, opt, extent)->
  width = $('#legend').width()
  height = $('#legend').height()
  count = colors.range().length
  $('#top h2').text opt.long_title
  svg = d3.select '#legendSVG'
  svg.selectAll 'g'
    .remove()

  svg.append "g"
    .selectAll "rect"
    .data(
      colors.range().map (color, idx) ->
        val = colors.invertExtent(color)[1]
        idx: idx
        max: if val then val else colors.invertExtent(color)[0] + 1
    )
    .enter()
    .append "rect"
    .attr "class", (d)-> "highlight-#{d.idx} highligh-legend"
    .attr "height", (height/count)
    .attr "y", (d) ->
      (height/count) * d.idx
    .attr "width", (height/count)
    .style "fill", (d)->
      colors(d.max-1)

  svg.select('g')
    .selectAll "text"
    .data(
      colors.range().map (color, idx) ->
        [min, max] = colors.invertExtent color
        if opt.format is "int" and min then min+= 1
        max = if max then max else extent[1]
        min = if min then min else extent[0]
        idx: idx
        max: if max then max else extent[1]
        min: if min then min else extent[0]
    )
    .enter()
    .append 'text'
    .attr "class", (d)-> "svg-text highlight-#{d.idx} highligh-legend"
    .attr "x", (height/count) + 10
    .attr "y", (d) ->
      (height/count) * d.idx + 10
    .text (d)->
      if d.min >= d.max then "#{valToString(d.max, opt.format)}"
      else "#{valToString(d.min,opt.format)} - #{valToString(d.max, opt.format)}"


valToString = (val, format) ->
  switch format
    when 'money' then "$#{parseFloat(val).formatPrice()}"
    when 'int' then "#{parseInt(val)}"
    when 'float' then "#{parseFloat(val).formatPrice()}"


computeValue = (feature, divisor, data) ->
  features = _.map window.selected_opts, (s) -> "#{feature}_#{s}"
  sum = _.reduce features, ( (m, f) ->
    parseFloat(data.properties[f]) + m
  ), 0
  if divisor
    divisors = _.map window.selected_opts, (s) -> "#{divisor}_#{s}"
    div = _.reduce divisors, ( (m, f) ->
      parseFloat(data.properties[f]) + m
    ), 0
    if div then sum/div else 0
  else sum

perArea = (feature, data) ->
  features = _.map window.selected_opts, (s) -> "#{feature}_#{s}"
  sum = _.reduce features, ( (m, f) ->
    parseFloat(data.properties[f]) + m
  ), 0
  sum / data.properties['area']

selectDataOption = (opt) ->
  window.selected_data = opt
  $('.spinner').show()
  $('#legendSVG').hide()
  _.defer renderDataOption, global_opts[opt]

global_opts =
  data_points:
    title : "Properties for sale per sq.km."
    long_title : "Properties for sale per square kilometer"
    feature: _.partial perArea, "data_points"
    format: 'float'
    count_feature: _.partial computeValue, "data_points", null
    colors: colorbrewer.Greens[9]
  avg_price:
    title : "Average Price"
    long_title : "Average property price"
    feature: _.partial computeValue, "price", "data_points"
    count_feature: _.partial computeValue, "data_points", null
    format: 'money'
    colors: colorbrewer.Purples[9]
  pp_foot:
    title : "Price per square foot"
    long_title : "Average price per square foot"
    feature: _.partial computeValue, 'pp_foot', 'pp_foot_points'
    count_feature: _.partial computeValue, 'pp_foot_points', null
    format: 'money'
    colors: colorbrewer.Blues[9]

setupColors = ->
  _.each global_opts, (m,key) ->
    $(".dataOption[data-id='#{key}'] .data-color").css 'background-color', m.colors[3]

$(document).ready setupColors

bounds = null
path = null
svg = null
data = null
currentOption = null
# montreal's latitude and logitue
loc = [45.5, -73.5]
southWest = L.latLng(45.16, -74.27)
northEast = L.latLng(45.83, -73.18)
bnds = L.latLngBounds southWest, northEast

#create the map
map = L.map 'map'
  .setView loc, 11
  .setMaxBounds bnds
L.tileLayer  'http://{s}.www.toolserver.org/tiles/bw-mapnik/{z}/{x}/{y}.png',
# L.tileLayer  'http://{s}.tile.stamen.com/toner/{z}/{x}/{y}.png',
    attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a>',
    minZoom: 10
  .addTo(map)
map.on "viewreset", redrawSVG


d3.json "assets/montreal.topo.json", (error, mtl) ->
  svg = d3.select(map.getPanes().overlayPane).append("svg")
  data = topojson.feature(mtl, mtl.objects['montreal.data'])
  bounds = d3.geo.bounds data
  path = d3.geo.path().projection(project)
  svg.append "g"
    .on "mouseover", (d) -> $('#popover').show()
    .on "mouseout", (d) -> $('#popover').hide()
    .attr "class", "leaflet-zoom-hide"
    .selectAll "path"
    .data data.features
    .enter()
    .append "path"
    .attr "class", "land"
    .attr "d", path

  redrawSVG()
  selectDataOption window.selected_data

