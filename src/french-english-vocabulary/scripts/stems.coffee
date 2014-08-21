

renderStems  = (lang) ->
  $el = $ ".stems.#{lang} .text"

  data = window.stems[lang]
  html = _.reduce data, (memo,d,idx)->
    space = if idx is 0 then ""
    else if d.word.length is 1 and _([',', '.', ';']).contains d.word then ""
    else " "
    "#{memo}#{space}<span data-id='#{idx}'>#{d.word}</span>"
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

  $container.find('span').removeClass 'hidden changed'

  if action is 'stem' then _.each data, (d, idx) ->
    $e = $container.find("[data-id=#{idx}]")
    unless d.stem.length then $e.addClass 'hidden'
    else unless d.stem is d.token then $e.addClass 'changed'
    if d.stem.length then $e.text d.stem

  else _.each data, (d, idx) -> $container.find("[data-id=#{idx}]").text d.word


$(window).load ->
  renderStems "english"
  $('.stems.english .menu .item').click _.partial toggleStems, 'english'

  renderStems 'french'
  $('.stems.french .menu .item').click _.partial toggleStems, 'french'

