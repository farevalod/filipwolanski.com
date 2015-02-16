do ($ = jQuery, window, document) ->

  renderStems  = (lang) ->
    $el = $ ".viz.#{lang} .text"

    data = window.example[lang]
    html = _.reduce data, (memo,d,idx)->
      space = if idx is 0 then ""
      else if d.word.length is 1 and _([',', '.', ';']).contains d.word then ""
      else " "
      "#{memo}#{space}<div class='word' data-id='#{idx}' data-word='#{d.word}'>#{d.word}</div>"
    , ""

    $el.html html


  toggleStems = (lang, action) ->

    data = window.example[lang]
    $container = $ ".viz.#{lang} > .text"

    $total = $ ".viz.#{lang} > .total"
    $total.removeClass 'active'

    $container.find('.word').removeClass 'hidden changed duplicate unique nonunique'

    count = 0

    if action is 'stem'
      _.each data, (d, idx) ->
        $e = $container.find("[data-id=#{idx}]")


        unless d.stem.length then $e.addClass 'hidden'
        else unless d.stem is d.token then $e.addClass 'changed'
        if d.stem.length then $e.text d.stem

    else if action is 'count'
      _.each data, (d, idx) ->
        $e = $container.find("[data-id=#{idx}]")

        if d['unique-stem']
          $e.addClass('unique')
            .text d.stem
            .attr 'data-count', ++count
        else
          $e.addClass('nonunique')

      $total.text "Total: #{count}"
      $total.addClass 'active'

    else
      _.each data, (d, idx) -> $container.find("[data-id=#{idx}]").text d.word


  showFilter = (ev) ->
    $el = $ ev.currentTarget
    filter = if $el.hasClass 'stemmed' then '.changed'
    else if $el.hasClass 'removed' then '.hidden' else '.duplicate'

    for lang in ['english', 'french']
      $container = $ ".viz.#{lang} > .text"
      $container.find(".word").not(filter).addClass 'hide'

  clearFilter =  ->
    for lang in ['english', 'french']
      $container = $ ".viz.#{lang} > .text"
      $container.find('.word').removeClass 'hide'

  $(window).load ->
    langs = ['english', 'french']

    renderStems l for l in langs

    currentAction = 'text'
    filterEls = $ '#stem-viz .filter'
    filterEls.on 'click', (ev) ->
      ct = $ ev.currentTarget
      action = ct.attr 'data-id'
      if action is currentAction then return

      currentAction = action
      filterEls.removeClass 'active'
      ct.addClass 'active'

      toggleStems l, action for l in langs

      if action is "text"
        $("#unique-leg .count-showing").hide()
        $("#unique-leg .stem-showing").hide()
        $("#unique-leg .text-showing").show()

      else if action is "count"
        $("#unique-leg .stem-showing").hide()
        $("#unique-leg .text-showing").hide()
        $("#unique-leg .count-showing").show()

      else
        $("#unique-leg .count-showing").hide()
        $("#unique-leg .text-showing").hide()
        $("#unique-leg .stem-showing").show()

      window.setTimeout ->
        $(document.body).trigger "sticky_kit:recalc"
      , 400


    $("#unique-leg .filter").hover showFilter, clearFilter

    scroller = new IScroll $('.stem-viz-container').get(0),
      mouseWheel: false
      scrollbars: false
      scrollX: true
      scrollY: false
      eventPassthrough: true
      preventDefault: false

    wid = $(window).width()
    if (wid < 720) then scroller.scrollTo (wid-720)/2, 0


