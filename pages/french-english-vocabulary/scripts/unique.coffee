do ($ = jQuery, d3, window, document) ->

  processUniqueAuthors = ->

    u = window.unique
    authors =_.map _.extend(u.english, u.french), (v,k) ->
      v.author = k
      return v
    _.sortBy _.values(authors), 'author'

  renderUniqueMenu = ($parent, data, selectItem) ->

    $menu = $parent.find '.menu'

    selectedFirst = false

    _.each data, (d) ->
      $author = $ "<div />"
        .addClass "item-title"
        .text d.author
        .on "click", ->
          $parent.find('.item-title').removeClass 'active'
          $parent.find('.sub-item').removeClass 'active'

          $author.addClass 'active'
          selectItem d

      $menuItem = $ "<div />"
        .addClass "item"
        .append $author

      unless selectedFirst
        selectedFirst = true
        _.defer ->
          $author.addClass 'active'
          selectItem d

      books = _.sortBy d.books, 'title'

      _.each books, (book) ->
        $subitem = $ '<div />'
          .addClass 'sub-item'
          .text book.title
          .on "click", (ev) ->
            $parent.find('.item-title').removeClass 'active'
            $parent.find('.sub-item').removeClass 'active'
            $subitem.addClass 'active'
            selectItem book
        $menuItem.append $subitem

      $menu.append $menuItem


  calculateUniqueLayout = (svg, dimensions, data) ->

    $('.spinner').removeClass 'none'

    window.setTimeout ->
      vals = _.pluck data['top-words'], 'score'
      # minVal = _.min(vals)
      # if minVal < 1 then vals = _.map vals, (v) -> v - (minVal - 1)

      scale = d3.scale
        .pow().exponent(0.5)
        .domain([_.min(vals), _.max(vals)]).range([10, 50])

      words = data['top-words'].map (d) ->
          text: d.word.toUpperCase()
          size: scale(d.score)

      d3.layout.cloud().size([dimensions.width,dimensions.height])
        .words words
        .padding(1)
        .rotate(-> ~~(Math.random() * 2) * 90)
        .font("fira")
        .fontSize((d) -> d.size)
        .on("end", _.partial renderWordMapSVG, svg, dimensions)
        .start()
    , 1000/60

  uniqueFillMethod = d3.scale.category20()

  renderWordMapSVG = (svg, dimensions, words) ->

    svg.selectAll('text').remove()
    svg
      .selectAll("text")
      .data(words)
      .enter()
      .append("text")
      .style("font-size", (d) -> d.size + "px")
      .style("font-family", "fira")
      .style("fill", (d, i) -> uniqueFillMethod i)
      .attr("text-anchor", "middle")
      .attr("transform", (d) -> "translate(" + [d.x, d.y ] + ")rotate(" + d.rotate + ")")
      .text (d) -> d.text.toUpperCase()

    _.defer ->
      $('.spinner').addClass 'none'

  createWordMapSVG = (container, dimensions) ->

    spinner = d3.select(container)
      .append 'div'
      .attr 'class', 'spinner none'

    spinner.append('div').attr 'class', 'bounce1'
    spinner.append('div').attr 'class', 'bounce2'
    spinner.append('div').attr 'class', 'bounce3'

    d3.select(container)
      .append("svg")
      .attr("width", dimensions.width)
      .attr("height", dimensions.height)
      .append("g")
      .attr("transform", "translate(#{dimensions.width/2},#{dimensions.height/2})")


  $(document).ready ->

    $parent = $ '.viz.words'
    $wordMapContainer = $parent.find "#unique"
    wordMapDimensions =
      height: $wordMapContainer.height()
      width: $wordMapContainer.width()

    svg = createWordMapSVG $wordMapContainer.get(0), wordMapDimensions

    renderUniqueMenu $parent, processUniqueAuthors(),
      _.partial calculateUniqueLayout, svg, wordMapDimensions

    $wordMapContainer.stick_in_parent()
