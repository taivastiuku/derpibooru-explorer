# LOADING

###* @license
# Derpibooru Explorer
# Copyright (C) 2014 taivastiuku@gmail.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# https://www.gnu.org/licenses/gpl-2.0.html
#
# Source for this file can be found at:
# https://tiuku.me/static/derpibooru_explorer.coffee
###

"use strict"
app = null
booru = unsafeWindow.booru

inputSelected = -> document.activeElement.tagName in ["INPUT", "TEXTAREA"]


window.Router = Backbone.Router.extend
  initialize: (config) ->
    console.debug "Initializing router"
    @config = config
    @session = new Session(config.LOGOUT_ENDS_SESSION)
    @stars = new Stars()
    @imageQueue = new ImageQueue()

    $($(".dropdown_menu")[0]).prepend("<a href='/images/?highlights'><i class='fa fa-fw fa-birthday-cake'></i> Highlights</a>")

    KeyboardJS.on "e", =>
      console.debug "Next in queue"
      @imageQueue.next() unless inputSelected()
    console.debug "Router initialized"

  routes:
    "tags/artist-colon-:artist_name": "similarArtists"

    "": "thumbs"
    "tags/:tag": "thumbs"
    "search": "thumbs"
    "search/": "thumbs"
    "search/index": "thumbs"
    "images": "thumbs"
    "images/": "thumbs"
    "images/favourites": "thumbs"
    "images/favourites/:page": "thumbs"
    "images/upvoted": "thumbs"
    "images/upvoted/:page": "thumbs"
    "images/uploaded": "thumbs"
    "images/uploaded/:page": "thumbs"
    "images/watched": "thumbs"
    "images/watched/:page": "thumbs"
    "images/page/": null  # I need pictures, pictures of ponies
    "images/page/:page": "thumbs"

    "images/:image_id": "similarImages"
    ":image_id": "similarImages"

    "art/*path": "forum"
    "pony/*path": "forum"
    "writing/*path": "forum"
    "dis/*path": "forum"
    "rp/*path": "forum"
    "meta/*path": "forum"


  similarArtists: (artist_name) ->
    return unless artist_name
    console.debug "Add links to similar artists"

    container = $("<div>")
      .append("<h3 style='display:inline-block'>Similar artists: </h3>")

    $.get "https://tiuku.me/api/for-artist/#{artist_name}?session=#{app.session.id}", (data) ->
      _.each data.recommendations, (item) ->
        container.append templates.artistTag({name: item.name, url: item.link})

    $("#tag_info_box")
      .after("<hr>")
      .after(container)

    @thumbs()

  thumbs:  ->
    if window.location.search.indexOf("?highlights") > -1
      console.debug "Getting recommendations"
      new HighlightsView(user: app.session.user)
    else
      console.debug "Add queue-button to thumbnails"
      _.each $(".image.bigimage .imageinfo.normal"), (infoElement) ->
        new ThumbnailInfoView({el: infoElement, type: "big"})

      _.each $(".image.normalimage .imageinfo.normal"), (infoElement) ->
        new ThumbnailInfoView({el: infoElement, type: "normal"})

  similarImages: (image_id) ->
    return if isNaN parseInt(image_id)
    console.debug "Add list of similar images"

    target = $(".image_show_container")
      .after(new ImageView(imageId: image_id).el)

    if app.config.VIDEO_MODE
      $("img#image_display").on "load", ->
        height = $(".image_show_container").height()
        $("#imagelist_container.recommender").height(height - 3)
    else
        target.before("<hr>")

    if app.config.HATS
      setTimeout( ->
        today = new Date()
        month = today.getUTCMonth() + 1
        day = today.getUTCDate()
        if month == 12 and day > 21 and day < 27
          $(".post-avatar").append("<img class='hat-comment' src='https://tiuku.me/static/pic/jul.gif'>")
      , 3500)

  forum: (path) ->
    if app.config.HATS
      today = new Date()
      month = today.getUTCMonth() + 1
      day = today.getUTCDate()
      if month == 12 and day > 21 and day < 27
        $(".post-avatar").append("<img class='hat' src='https://tiuku.me/static/pic/jul.gif'>")


window.HighlightsView = Backbone.View.extend
  el: "#imagelist_container"
  initialize: (options) ->
    @$el.html("")
    @offset = 0
    @highlights = []
    @user = options.user
    @load()

  events:
    "click .recommender.load-more": "loadMore"

  load: ->
    $.get("https://tiuku.me/api/highlights/#{@user}?session=#{app.session.id}&offset=#{@offset}", (data) =>
      @highlights = @highlights.concat(data.recommendations)
      @render()
    ).fail =>
      console.debug("Server error")
      @$el.append("<h1>Server error</h1>")

  render: ->
    @$el.html("<div class='metabar'><div class='metasection'><strong>Highlighted images for #{@user}</srong></div></div>")
    _.each @highlights, (item) =>
      hiddenTags = _.intersection(item.tags, booru.hiddenTagList)
      if hiddenTags.length <= 0
        @$el.append new ThumbnailView(image: item).el
    @$el.append(templates.loadMoreImage())
    @$el.append(" ")

  loadMore: (event) ->
    $(event.target).remove()
    @offset = if @highlights.length > 0 then @highlights.slice(-1)[0]["id_number"] else 0
    @load()


window.ImageView = Backbone.View.extend
  tagName: "div"
  id: "imagelist_container"
  className: "recommender"
  initialize: (options) ->
    @offset = 0
    @recommendations = []
    @stars = new Stars()
    @image =
      id_number: options.imageId
      is_faved: -> $(".fave_link.faved").length > 0
      is_upvoted: -> $(".vote_up_link.voted_up").length > 0
      is_downvoted: -> $(".vote_down_link.voted_down").length > 0
      fave: -> $($(".favourites")[0]).click()
      upvote: -> $($(".upvote-span")[0]).click()
      downvote: -> $($(".downvote-span")[0]).click()

    KeyboardJS.on "1", (event) =>
      console.debug("fave")
      unless inputSelected()
        new NotificationView
          fa: "fa-star"
          off: @image.is_faved()
        @image.fave()

    KeyboardJS.on "2", (event) =>
      console.debug("upvote")
      unless inputSelected()
        new NotificationView
          fa: "fa-arrow-up"
          off: @image.is_upvoted()
        @image.upvote()

    KeyboardJS.on "3", (event) =>
      console.debug("downvote")
      unless inputSelected()
        new NotificationView
          fa: "fa-arrow-down"
          off: @image.is_downvoted()
        @image.downvote()

    @load()

  events:
    "click .recommender.load-more": "loadMore"
    "click .recommender.next-in-queue": -> app.imageQueue.next()

  loadMore: (event) ->
    $(event.target).remove()
    @offset += 8
    @load()

  load: ->
    $.get("https://tiuku.me/api/for-image/#{@image.id_number}?session=#{app.session.id}&offset=#{@offset}", (data) =>
      @recommendations = @recommendations.concat(data.recommendations)
      @stars.add(@image.id_number, data.stars) if data.stars
      @render()
    ).fail ->
      console.debug("Server error")
      @renderFailure()

  renderFailure: ->
    console.debug("Rendering failure message")
    @$el
      .html(templates.similarImagesStars(appStars: @stars.get()))
      .append("<div>Data load error</div>")
    return @

  render: ->
    @$el.html(templates.similarImagesStars(appStars: @stars.get()))
    if @recommendations.length <= 0
      console.debug("No thumbnails to render")
      @$el.append("<div>No recommendations</div>")
    else
      console.debug("Rendering thumbnails")
      _.each @recommendations, (item) =>
        hiddenTags = _.intersection(item.tags, booru.hiddenTagList)
        if hiddenTags.length <= 0
          @$el.append new ThumbnailView(image: item).el
          @$el.append(" ")


      if app.config.VIDEO_MODE is true
        @$el.append(templates.loadMoreBar())
        @$el.append(templates.nextInQueueBar())
      else
        @$el.append(templates.loadMoreImage())
        @$el.append(" ")
        @$el.append(templates.nextInQueueImage())

    return @


window.ThumbnailView = Backbone.View.extend
  tagName: "div"
  className: "image bigimage recommender"

  events:
    "click .add-queue": "queue"

  initialize: (options) ->
    @image = options.image
    spoileredTags = _.intersection(@image.tags, booru.spoileredTagList)
    # TODO Recommendation = Backbone.Model.extend ...
    _.extend @image,
      spoileredTags: spoileredTags
      isFaved: => _.contains(@image.tags, "faved_by:#{app.session.user}")
      isSpoilered: -> spoileredTags.length > 0
      isQueued: => app.imageQueue.contains(@image.id_number)
    @short_image = @image.image.replace(/__[a-z0-9+_-]+\./, ".")
    @render()

  render: ->
    @$el.html templates.thumbnail
      image: @image
      short_image: @short_image

  queue: ->
    app.imageQueue.toggle(@image.id_number)
    @render()


window.ThumbnailInfoView = Backbone.View.extend
  initialize: (options) ->
    @el = options.el
    @type = options.type
    try
      @link = @$el.parent()
        .attr("data-download-uri")
        .replace(/[/]download[/]/, "/view/")
        .replace(/__[a-z0-9+_-]+\./, ".")
    catch error
      @link = ""
    @imageId = parseInt(@$el.find(".comments_link").attr("href").split("#")[0].slice(1))
    @render()

  events:
    "click .add-queue": "queue"

  render: ->
    @remove() if isNaN(@imageId)
    @$el.find(".add-queue").remove()
    @$el.find(".id_number").remove()

    if @type == "big"
      @$el.prepend("<a href='#{@link}' class='id_number' title='#{@imageId}'><i class='fa fa-image'></i> #{@imageId}</a>")
      if app.imageQueue.contains(@imageId)
        @$el.append("<span class='add-queue queued'%><a><i class='fa fa-plus-square'></i> in queue</a></span>")
      else
        @$el.append("<span class='add-queue'><a><i class='fa fa-plus-square'></i> Queue</a></span>")

    else if @type == "normal"
      @$el.prepend("<a href='#{@link}' class='id_number' title='#{@imageId}'><i class='fa fa-image'></i></a>")
      if app.imageQueue.contains(@imageId)
        @$el.append("<span class='add-queue queued'%><a><i class='fa fa-plus-square'></i></a></span>")
      else
        @$el.append("<span class='add-queue'><a><i class='fa fa-plus-square'></i></a></span>")

  queue: ->
    app.imageQueue.toggle(@imageId)
    @render()


window.NotificationView = Backbone.View.extend
  tagName: "div"
  className: "over-notify"
  initialize: (options) ->
    return if options.fa is undefined
    @$el.append $("<span class='fa #{options.fa} #{if options.off is true then "off" else ""}'>")

    $("#content").append(@el)
    setTimeout(=>
      @$el.fadeOut("fast", => @remove())
    , 1000)


class ImageQueue
  constructor: ->
    console.debug "Initializing queue"
    @load()
    @actionCalled = false

  load: ->
    @queue = JSON.parse(localStorage.getItem("derpQueue")) or []
    @history = JSON.parse(localStorage.getItem("derpHistory")) or []

  add: (id) ->
    id = parseInt(id)
    return if isNaN(id)
    console.debug("Adding ##{id} to queue")
    @load()  # User may have multiple windows open, load to ensure that we
             # have the most current queue.
    new NotificationView(fa: "fa-cloud-download")
    @queue.push(id)
    @save()

  remove: (id) ->
    id = parseInt(id)
    return if isNaN(id)
    console.debug("Removing ##{id} to queue")
    @load()
    new NotificationView(fa: "fa-cloud-download", off: true)
    @queue = _.filter @queue, (queue_id) -> queue_id != id
    @save()

  toggle: (id) ->
    id = parseInt(id)
    return if isNaN(id)
    console.debug("Toggling ##{id}")
    @load()
    if _.contains(@queue, id)
      @remove(id)
    else
      @add(id)

  next: ->
    new NotificationView(fa: "fa-arrow-right")
    @load()  # User may have multiple windows open, load to ensure that we
             # have the most current queue.

    nextId = @queue.shift()
    return if nextId is undefined or @actionCalled
    @actionCalled = true

    console.debug("Moving to next: ##{nextId}")
    @history.unshift(nextId)
    @save()
    document.location = "/#{nextId}"

  save: ->
    console.debug("Saving queue")
    localStorage.setItem("derpQueue", JSON.stringify(@queue))
    localStorage.setItem("derpHistory", JSON.stringify(@history))

  contains: (id) -> _.contains(@queue, id)

class Stars
  constructor: ->
    @_stars = JSON.parse(localStorage.getItem("derpStars")) or {}

  get: ->
    return @_stars

  add: (imageId, stars) ->
    return if imageId is undefined or _.isEmpty(stars)

    imageStars = @_stars[imageId]

    if imageStars is undefined
      @_stars[imageId] = stars
    else
      _.each stars, (star) =>
        imageStars.push(star) unless _.contains(imageStars, star)

    localStorage.setItem("derpStars", JSON.stringify(@_stars))


class Session
  # Using cookies from userscript seems dangerous
  constructor: (@logoutEndsSession=true) ->
    console.debug "Initializing session"
    @user = booru.userName
    oldID = localStorage.getItem "derpSession"
    oldUser = localStorage.getItem "derpUser"

    if @user != oldUser and @logoutEndsSession is true
      console.debug "User changed: #{oldUser} -> #{@user}"
      @newSession()
    else if oldID is null
      console.debug "No session id: New Session"
      @newSession()
    else
      console.debug "Continue session"
      @id = oldID

  newSession: ->
    @id = @_makeId()
    localStorage.setItem "derpSession", @id
    localStorage.setItem "derpUser", @user
    localStorage.setItem "derpStars", null
    localStorage.setItem "derpQueue", null
    localStorage.setItem "derpHistory", null

  _makeId: ->
    randChar = ->
        chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return chars.charAt(Math.floor(Math.random() * chars.length))

    return _.map([1..16], randChar).join("")


window.templates = {}
window.templates.thumbnail = _.template("
<div class='imageinfo normal'>
    <span>
        <a href='<%= short_image %>' class='id_number' title='<%- image.id_number %>'><i class='fa fa-image'></i> <%- image.id_number %></a>
        <span class='fave-span<% if (image.isFaved()) {print('-faved');} %>'>
            <i class='fa fa-star'></i>
            <span class='favourites'><%- image.favourites %></span>
        </span>
        <i class='fa fa-arrow-up vote-up'></i>
        <span class='score'><%- image.score %></span>
        <a href='/<%= image.id_number %>#comments' class='comments_link'><i class='fa fa-comments'></i></a>

        <% if (image.isQueued()) { %>
        <span class='add-queue queued'%><a><i class='fa fa-plus-square'></i> in queue</a></span>
        <% } else { %>
        <span class='add-queue'><a><i class='fa fa-plus-square'></i> queue</a></span>
        <% } %>
    </span>
</div>
<div class='image_container thumb'><a href='/<%= image.id_number %>'><% if (image.isSpoilered()) { print(image.spoileredTags.join(', ')); } else { %><img src='<%= image.thumb %>' /><% } %></a></div>
")

window.templates.nextInQueueImage = _.template("
<div class='image bigimage recommender next-in-queue'>
    <div class='imageinfo normal spacer'></div>
    <div class='image_container thumb'>
        <a>Next in queue <i class='fa fa-arrow-right'></i></a>
    </div>
</div>
")

window.templates.loadMoreImage = _.template("
<div class='image bigimage recommender load-more'>
    <div class='imageinfo normal spacer'></div>
    <div class='image_container thumb'>
        <a>Load more</a>
    </div>
</div>
")

window.templates.nextInQueueBar = _.template("
<div class='image bigimage recommender next-in-queue next-in-queue-bar'>
    <div><a>Next in queue <i class='fa fa-arrow-right'></i></a></div>
</div>
")

window.templates.loadMoreBar = _.template("
<div class='image bigimage recommender load-more load-more-bar'>
    <div>
        <a>Load more</a>
    </div>
</div>
")

window.templates.similarImagesStars = _.template("
<div id='similars-title'>
    <h6>Similar Images</h6>
    <% _.each(appStars, function(stars, id_number) { %>
        <% _.each(stars, function(star) { %>
            <a href='/<%- id_number %>' title='<%- star %>'>
                <i class='fa fa-star'></i>
            </a>
    <% }); }); %>
</div>
")

window.templates.artistTag = _.template("
<span class='tag tag-ns-artist'>
    <a href='<%= url %>'><%- name %></a>
</span>
")

# Userscripts do not seem to allow loading other than javascript files.
# I'll just inject the CSS straight into <head>


videoModeStyles = "
<style type='text/css'>
.image_show_container {
    width: 720px;
    display: inline-block;
}
#imagelist_container.recommender {
    display: inline-block;
    width: 528px;
    height: 720px;
    overflow-y: scroll;
    vertical-align: top;
#image_display {
    max-width: 100%;
    height: auto;
}
</style>
"

$("head").append("
<style type='text/css'>

.image-warning, #imagespns {
    float: left;
}
.over-notify {
   border-radius: 5px;
   padding: 10px;
   position: fixed;
   right: 37%;
   top: 10px;
   line-height: 100px;
   width: 120px;
   height: 120px;
   font-size: 120px;
   text-align: center;
   background-color: rgba(90, 90, 90, 0.3);
}
.over-notify .fa.off {
    color: black;
}
.over-notify .fa-star {
    color: gold;
}
.over-notify .fa-arrow-up {
    color: #67af2b;
}
.over-notify .fa-arrow-down {
    color: #cf0001;
}
.over-notify .fa-arrow-right, .over-notify .fa-cloud-download {
    color: DeepPink;
}
.recommender .fave-span {
    color: #c4b246;
}
.recommender .fave-span-faved {
    display: inline!important;
    color: white!important;
    background: #c4b246!important;
}
.recommender .vote-up {
    color: #67af2b;
}
.recommender .vote-down {
    color: #cf0001;
}
.recommender.load-more-bar.bigimage.image, .recommender.next-in-queue-bar.bigimage.image {
    width: 506px;
}
.recommender.next-in-queue-bar.bigimage.image {
    margin-bottom: 600px;
}
.recommender.load-more-bar div, .recommender.next-in-queue-bar div {
    width: 100%;
    height: 100%;
    text-align: center;
    line-height: 50px;
}
.recommender.load-more a, .recommender.next-in-queue a {
    cursor: pointer;
}
.imageinfo.normal.spacer {
    height: 12px;
}
.id_number {
    margin-right: 2px;
    padding-left: 2px;
    padding-right: 2px;
}
.id_number:hover {
    color: white;
    background: #57a4db;
}

.add-queue {
    margin-left: 2px;
    padding: 0 2px;
}
.add-queue a {
    cursor: pointer;
}
.add-queue.queued, .add-queue:hover{
    background: #57a4db;
}
.add-queue.queued a, .add-queue a:hover {
    color: white!important;
}
#similars-title h2 {
    display: inline-block;
}
#similars-title .fa-star {
    color: gold;
    cursor: help;
}
::selection {
    background: pink;
}
</style>
")

hatStyles = "<style type='text/css'>

.post, .post-meta {
    overflow: visible!important;
}

.post-avatar {
    position: relative;
}

.hat {
    position: absolute;
    top: -100px;
    left: -26px;
}

.hat-comment {
    position: absolute;
    top: -36px;
    left: -4px;
    transform: scale(1.28, 1.28);
}
</style>"
#READY.

window.runDerpibooruExplorer = (config) ->
  #RUN
  if config.VIDEO_MODE is true
    $("head").append(videoModeStyles)
    $(document).scrollTop(90)

  if config.HATS is true
    $("head").append(hatStyles)

  if config.DEBUG is false
      console.debug = -> return

  if config.KEYBOARD_SHORTCUTS is false
      KeyboardJS.on = -> return

  console.debug "Starting Derpibooru Explorer"
  app = new Router(config)
  Backbone.history.start
    pushState: true
    hashChange: false
  console.debug "Derpibooru Explorer started"
