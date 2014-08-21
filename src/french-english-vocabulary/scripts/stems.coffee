

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

  datasel = if action is 'text' then 'word' else 'stem'
  $container.find('span').removeClass 'hidden'
  _.each data, (d, idx) ->
    $e = $container.find("[data-id=#{idx}]")
    unless d[datasel].length then $e.addClass 'hidden'
    else $container.find("[data-id=#{idx}]").text d[datasel]


$(window).load ->
  renderStems "english"
  $('.stems.english .menu .item').click _.partial toggleStems, 'english'

