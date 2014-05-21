mouse =
  x: 0
  y: 0
  scrollTop: 0
document.addEventListener "mousemove", ((e) ->
  mouse.x = e.clientX or e.pageX
  mouse.y = e.clientY or e.pageY
), false
document.addEventListener "scroll", ((e) ->
  mouse.scrollTop = document.body.scrollTop
), false

svg = d3.select "#map"
popover = d3.select "#popover"

projection = d3.geo.transverseMercator()
  .scale 60000
  .rotate [73.6, -45.6]
path = d3.geo.path().projection(projection)

d3.json "assets/montreal.topo.json", (error, mtl) ->
  console.log error
  svg.append "g"
    .on "mouseover", (d) ->
      popover
        .style 'opacity', 100
    .on "mouseout", (d) ->
      popover
        .style 'opacity', 0
    .selectAll "path"
    .data(topojson.feature(mtl, mtl.objects['montreal.data']).features)
    .enter()
    .append("path")
    .attr("class", "land")
    .attr("d", path)
    .on "mousemove", (d) ->
      popover.style 'top', (mouse.y + mouse.scrollTop + 50 ) + 'px'
      .style 'left', (mouse.x - 100) + 'px'
      .select ".title"
      .text d.properties.name
      popover.select ".body"
        .text d.properties.data_points
      #console.log d.properties
      #console.log d.properties.name, d.properties


