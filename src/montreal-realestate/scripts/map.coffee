width = 960
height = 1160

svg = d3.select "body"
  .append "svg"
  .attr "width", width
  .attr "height", height

projection = d3.geo.mercator().scale(1000).translate([
  width
  height*3
])

path = d3.geo.path().projection(projection)

d3.json "assets/montreal.topo.json", (error, mtl) ->
  svg.insert("path", ".graticule")
    .datum(topojson.feature(mtl, mtl.objects.montreal))
    .attr("class", "land")
    .attr("d", path)



