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
  $("#dataTitle").text opt.title
  $("#dataValue").text "$" + opt.feature(d).formatPrice()
  $("#dataPoints").text opt.count_feature(d)
  console.log d.properties

colorMap = (feature, cols) ->
  colors = createColors data, feature, cols
  d3.selectAll "path"
    .style "fill", (d)->
      price = feature d
      if price  > 0 then colors price else "#ffffff"
    .style "opacity", (d) ->
      price = feature d
      if price  > 0 then 0.5 else 0

renderDataOption = (opt) ->
  colorMap opt.feature, opt.colors
  d3.selectAll("path").on "mousemove", _.partial drawPopover, opt

selected_opts = ['house', 'town', 'condo']

computeValue = (feature, divisor, data) ->
  features = _.map selected_opts, (s) -> "#{feature}_#{s}"
  sum = _.reduce features, ( (m, f) ->
    parseFloat(data.properties[f]) + m
  ), 0
  if divisor
    divisors = _.map selected_opts, (s) -> "#{divisor}_#{s}"
    div = _.reduce divisors, ( (m, f) ->
      parseFloat(data.properties[f]) + m
    ), 0
    sum/div
  else sum


selectDataOption = (opt) ->
  if opt isnt currentOption
    renderDataOption switch opt
      when "avg_price"
        title : "Average Price"
        feature: _.partial computeValue, "price", "data_points"
        count_feature: _.partial computeValue, "data_points", null
        colors: colorbrewer.YlGn[9]
      when "pp_foot"
        title : "Price per square foot"
        feature: _.partial computeValue, 'pp_foot', 'pp_foot_points'
        count_feature: _.partial computeValue, 'pp_foot_points', null
        colors: colorbrewer.PuBu[9]
      else throw "unknown option"

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
  selectDataOption "avg_price"

