renderStems  = (lang) ->
  $el = $ ".stems.#{lang} .text"

  data = window.stems[lang]
  html = _.reduce data, (memo,d,idx)->
    space = if idx is 0 then ""
    else if d.word.length is 1 and _([',', '.', ';']).contains d.word then ""
    else " "
    "#{memo}#{space}<div class='word' data-id='#{idx}' data-word='#{d.word}'>#{d.word}</div>"
  , ""

  $el.html html


toggleStems = (lang, ev) ->
  $el = $ ev.currentTarget

  # the current element is already selected
  if $el.hasClass 'active' then return false

  $(".stems.#{lang} .menu .item").removeClass 'active'
  $el.addClass 'active'

  action = $el.attr 'data-id'
  data = window.stems[lang]
  $container = $ ".stems.#{lang} .text"

  $container.find('.word').removeClass 'hidden changed duplicate'

  uniques = []
  if action is 'stem'
    $(".stems.#{lang} .section .legend").show()
    _.each data, (d, idx) ->
      $e = $container.find("[data-id=#{idx}]")

      if d.stem.length
        if uniques.indexOf(d.stem) is -1 then uniques.push d.stem
        else $e.addClass 'duplicate'

      unless d.stem.length then $e.addClass 'hidden'
      else unless d.stem is d.token then $e.addClass 'changed'
      if d.stem.length then $e.text d.stem

  else
    $(".stems.#{lang} .section .legend").hide()
    _.each data, (d, idx) -> $container.find("[data-id=#{idx}]").text d.word


showFilter = (lang, ev) ->
  $el = $ ev.currentTarget
  filter = if $el.hasClass 'stemmed' then '.changed'
  else if $el.hasClass 'removed' then '.hidden' else '.duplicate'

  $container = $ ".stems.#{lang} .text"
  $container.find(".word").not(filter).addClass 'hide'

clearFilter = (lang) ->
  $container = $ ".stems.#{lang} .text"
  $container.find('.word').removeClass 'hide'

$(window).load ->
  for lang in ['english', 'french']
    renderStems lang
    $(".stems.#{lang} .menu .item").click _.partial toggleStems, lang
    $(".stems.#{lang} .legend .filter").hover _.partial(showFilter, lang), _.partial clearFilter, lang


