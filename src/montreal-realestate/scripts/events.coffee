#number formatter
Number::formatPrice = ->
    re = '\\d(?=(\\d{3})+\\.)'
    @toFixed(2).replace(new RegExp(re, 'g'), '$&,')

window.mouse =
  x: 0
  y: 0
  scrollTop: 0

# event handlers
$(document).mousemove (e) ->
  window.mouse.x = e.clientX or e.pageX
  window.mouse.y = e.clientY or e.pageY
$(document).scroll (e) -> window.mouse.scrollTop = document.body.scrollTop

#resize = ->
  #topHeight = document.getElementById('top').offsetHeight
  #bottomHeight = document.getElementById('bottom').offsetHeight
  ##$("#map").css "height", (window.innerHeight - topHeight - bottomHeight - 2) + "px"
  #$("#top").hide()
  #$("#bottom").hide()

  #map.invalidateSize()

#window.onresize = resize
#$(document).ready resize
$(".filterOption").click (e)->
  $(e.currentTarget).toggleClass 'active'
  options = []
  $(".filterOption").each (idx, el) ->
    if $(el).hasClass 'active' then options.push $(el).attr 'data-id'
  unless options.length
    ct = $(e.currentTarget)
    $(".filterOption").each (idx, el) ->
      unless $(el).attr('data-id') is ct.attr('data-id')
        $(el).addClass 'active'
        options.push $(el).attr 'data-id'
  window.selected_opts = options
  selectDataOption window.selected_data

$(".dataOption").click (e)->
  opt = $(e.currentTarget)
  $(".dataOption").removeClass 'active'
  opt.addClass "active"
  selectDataOption opt.attr 'data-id'

