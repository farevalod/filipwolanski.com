authorHeight = 3
scaleHeight = 2

$( document ).ready ->
  chart = d3.select "#chart"
  rem = parseFloat $("html").css 'font-size'
  desc = d3.select('.description-container')

  authorHeight *= rem
  scaleHeight *= rem
  chartWidth = $("#chart").width()

  d3.json "assets/words.json", (d)->
    writers = _.map d.english, (w, key) -> _.extend w,
      author: key
      language: "english"

    writers = writers.concat _.map d.french, (w,key) -> _.extend w,
      author: key
      language: "french"

    writers = _.sortBy writers, (w)-> -w['distinct-stem-count']
    max =  _.max _.pluck writers, 'distinct-stem-count'
    max = 30000
    stem_count = d3.scale.linear().domain [0,max]
      .range [0, chartWidth]

    invert_scale = d3.scale.linear().domain [max,0]
      .range [0, chartWidth]
    axis = d3.svg.axis()
      .scale invert_scale
      .orient "bottom"
      .ticks 6

    chart.attr "height", writers.length*authorHeight + scaleHeight + 2*rem

    chart.append 'g'
      .attr "transform", "translate(#{1.5*rem}, #{rem})"
      .attr 'class', 'x axis'
      .call axis

    chart.append('g')
      .attr "transform", "translate(#{1.5*rem}, #{rem})"
      .selectAll ".bar"
      .data writers
      .enter()
      .append "g"
      .attr "class", (d) -> "bar " + d['language']
      .append "rect"
      .attr "x", chartWidth
      .attr "y", (d,k)-> 0.40*rem + scaleHeight + authorHeight*k
      .attr "width", 0
      .attr "height", 0.5*authorHeight

    desc.selectAll('.author')
      .data writers
      .enter()
      .append 'div'
      .attr 'class', 'author'
      .html (w)-> """
          <div class="name">#{w.author}</div>
          <div class="dates">#{w.dates[0]}-#{w.dates[1]}</div>
        """

    _.defer ->
      chart.selectAll ".bar"
        .transition()
        .duration 1000
        .attr "x", (d)-> chartWidth - stem_count d['distinct-stem-count']
        .attr "width", (d)-> stem_count d['distinct-stem-count']
