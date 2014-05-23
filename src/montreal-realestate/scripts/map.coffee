bounds = null
path = null
loc = [45.5, -73.5]
southWest = L.latLng(45.16, -74.27)
northEast = L.latLng(45.83, -73.18)
bounds = L.latLngBounds(southWest, northEast)

resize = ->
  topHeight = document.getElementById('top').offsetHeight
  bottomHeight = document.getElementById('bottom').offsetHeight
  d3.select "#map"
    .style "height", (window.innerHeight - topHeight - bottomHeight - 2) + "px"

window.onresize = resize
resize()

map = L.map 'map'
  .setView loc, 11
  .setMaxBounds bounds
L.tileLayer 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a>',
    minZoom: 11
.addTo(map)

# leaflet defines the d3 geographic projection
project = (x) ->
  point = map.latLngToLayerPoint(new L.LatLng(x[1], x[0]))
  [point.x, point.y]

svg = d3.select(map.getPanes().overlayPane)
  .append("svg")

reset = ->
  bottomLeft = project(bounds[0])
  topRight = project(bounds[1])

  svg.attr("width", topRight[0] - bottomLeft[0])
    .attr("height", bottomLeft[1] - topRight[1])
    .style("margin-left", bottomLeft[0] + "px")
    .style("margin-top", topRight[1] + "px")

  svg.selectAll("g").attr("transform", "translate(" + -bottomLeft[0] + "," + -topRight[1] + ")")
  svg.selectAll("path").attr("d", path)

map.on "viewreset", reset

d3.json "assets/montreal.topo.json", (error, mtl) ->

  bounds = d3.geo.bounds(topojson.feature(mtl, mtl.objects['montreal.data']))
  colors = d3.scale.ordinal().domain(d3.range(0,2000)).range(colorbrewer.YlGn[9])
  path = d3.geo.path().projection(project)

  svg.append "g"
    .attr("class", "leaflet-zoom-hide")
    .selectAll "path"
    .data(topojson.feature(mtl, mtl.objects['montreal.data']).features)
    .enter()
    .append "path"
    .attr "class", "land"
    .attr "d", path
    .style "fill", (d)-> colors d.properties.data_points

  reset()


