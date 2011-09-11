class Integrator
  # Ben Fry's Integrator
  constructor: (@value, @target=null, @damping=0.3, @attraction=0.2) ->
    @mass = 1
    @targeting = if @target then true else false
    @vel = 0
    @force = 0.1

  update: ->
    if @targeting
      @force += @attraction * (@target - @value)
    accel = @force / @mass
    @vel = (@vel + accel) * @damping
    @value += @vel
    @force = 0

  set_target: (t) ->
    @targeting = true
    @target = t

class Bar
  constructor: (@name, @val, @pos_x, @pos_y, @width, @height, @color=[0, 0, 200]) ->
    @name_y = @pos_y + 18
    @tcolor = [360, 100, 80]

  draw: (p) ->
    p.stroke(40)
    p.fill(@color...)
    p.rect(@pos_x, @pos_y, @width, @height)
    p.fill(@tcolor...)
    p.textSize(20)
    p.text("#{@name}:#{@val}", 30, @name_y)

class Dialog
  constructor: (@marker, @pos_x, @pos_y, @width=null, @height=null) ->
    @offset = 300
    @stroke = 40

  draw: (p) ->
    p.stroke(@stroke)
    drawFrame(p, this)
    drawName(p, this)
    drawContents(p, this)

  drawFrame = (p, s) ->
    objs = s.marker.values
    [x, y] = [s.pos_x-s.offset, s.pos_y-objs.length/2*20-15]
    [w, h] = [600, objs.length*20+20]
    y = 2 if y < 0
    [r,g,b] = s.marker.bar.color
    p.fill(r, g-50, b)
    p.rect(x, y, max_val(objs)*12+40, h)
  
  max_val = (objs) ->
    max = 0
    for obj in objs
      len = obj.title.length
      max = len if len > max
    max
    
  drawName = (p, s) ->
    p.fill(s.marker.bar.tcolor...)
    p.textSize(30)
    p.pushMatrix()
    p.translate(p.width/2-s.offset-5, p.height/2)
    p.textAlign(p.CENTER)
    p.rotate(-p.PI/2)
    p.text(s.marker.name, 0, 0)
    p.popMatrix()
    
  drawContents = (p, s) ->
    p.textSize(15)
    p.textAlign(p.LEFT)
    objs = s.marker.values
    [x, y] = [s.pos_x-s.offset+15, s.pos_y-objs.length/2*20+10]
    y = 20 if y < 0
    p.fill(s.marker.bar.tcolor...)
    for obj, i in objs
      date = obj.time.substring(0,10)
      p.text("#{obj.title}(#{date})", x, y+i*20)

class Marker
  @MAX: 0; @MIN: 0; @SIZE: 0; @current: null
  constructor: (@name, @values) ->
    @size = @values.length
    Marker.MAX = @size if @size > Marker.MAX
    Marker.MIN = @size if @size < Marker.MIN
    Marker.SIZE += 1
    @bar = null
    @interpolator = null
  
total = null
[can_w, can_h] = [$(window).width()-100, 600]
markers = []
pitch = null
bg = [60, 30, 220]

bookmark = (p) ->
  p.setup = ->
    p.size(can_w, can_h)
    p.frameRate(15)
    p.smooth()
    p.colorMode(p.HSB, 230)
    pitch = (p.height-20)/Marker.SIZE
    for marker, i in markers
      cnt = marker.size
      name = marker.name
      val = p.map(cnt, 0, Marker.MAX, 0, p.width-100)
      marker.bar = new Bar(name, cnt, 0, i*pitch+10, 0, pitch-3)
      marker.interpolator = new Integrator(0, val)
      marker.dialog = new Dialog(marker, p.width/2, p.height/2)

  p.draw = ->
    p.background(bg...)
    Marker.current = null
    p.rectMode(p.CORNER)
    for marker in markers
      marker.interpolator.update()
      bar = marker.bar
      bar.width = marker.interpolator.value
      
      [x1, x2] = [bar.pos_x, bar.pos_x+bar.width]
      [y1, y2] = [bar.pos_y, bar.pos_y+bar.height]
      r = p.map(bar.val, Marker.MIN, Marker.MAX, 0, 255)
      if (x1 < p.mouseX < x2) and (y1 < p.mouseY < y2)
        bar.color = [r, 220, 220]
        Marker.current = marker
      else
        bar.color = [r, 170, 170]
      bar.draw(p)

    Marker.current.dialog.draw(p) if Marker.current

  p.mousePressed = ->
    if Marker.current
      url = "http://d.hatena.ne.jp/#{Marker.current.name}"
      p.link(url, "_new")

$ ->
  path = window.location.href.match(/\/\w+$/)
  $.ajax({
    url: "#{path}.json",
    dataType: 'json',
    beforeSend: ->
      $("#loading").show()
    success: (json)->
      $("#loading").hide()
      if json
        total = json.total
        $("#total").text(total)
        for name, vals of json.data
          markers.push( new Marker(name, vals) )
        
        canvas = $("#processing")[0]
        processing = new Processing(canvas, bookmark)
      else
        alert "No Bookmark Data or Too Big to handle it."
    error: ->
      alert "Something Go Wrong."
  })
