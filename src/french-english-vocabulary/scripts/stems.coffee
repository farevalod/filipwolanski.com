

renderStems  = (lang) ->
  $el = $ ".stems.#{lang}"

  data = window.stems[lang]
  html = _.reduce data, (memo,d,idx)->
    "#{memo}<span data-id='#{idx}'>#{d.word}</span> "
  , ""
  $el.html html

$(window).load ->
  renderStems "english"

