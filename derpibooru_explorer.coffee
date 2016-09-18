# LOADING

###* @license
# Derpibooru Explorer
# Copyright (C) 2014-2016 taivastiuku@gmail.com
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
csrfToken = -> $("input[name=authenticity_token]")[0].value

data2images = (image_data) ->
  images = if image_data.images then image_data.images else image_data.search
  raw_interactions = image_data.interactions
  interactions = {}
  _.each raw_interactions, (i) ->
    obj = interactions["#{i.image_id}"] or {}
    if i.interaction_type == "faved"
      obj.faved = true
    else if i.interaction_type == "voted"
      obj.voted = i.value
    interactions["#{i.image_id}"] = obj

  _.each images, (image) ->
    image.id = parseInt(image.id)
    image.tags = if image.tags then image.tags.split(", ") else []
    image.tag_ids = if image.tag_ids then _.map(image.tag_ids, (tag_id) -> parseInt(tag_id)) else []

    interaction = interactions[image.id]
    _.extend(image, interaction) if interaction
  return images

gm_get = (url, success, failure) ->
  GM_xmlhttpRequest({
    method: "GET"
    url: url
    onload: (response) ->
      if 200 <= response.status < 300
        success(JSON.parse(response.responseText))
      else
        failure(response)
  })

fakeClick = (target) ->
  evt = document.createEvent("MouseEvents")
  evt.initMouseEvent("click", true, true, unsafeWindow,
    0, 0, 0, 0, 0, false, false, false, false, 0, null)
  target.dispatchEvent(evt)

window.Router = Backbone.Router.extend
  initialize: (config) ->
    console.debug "Initializing router"
    @config = config
    @session = new Session(config.LOGOUT_ENDS_SESSION)
    @imageQueue = new ImageQueue()
    @imagesPerPage = null

    path = if window.location.pathname == "/images/" then "/images" else "/images/"
    $($(".dropdown__content")[0]).append("<a href='#{path}#queue' class='header__link'><i class='fa fa-cloud-download'></i> Queue</a>")

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
    "images/queue": "queue"
    "images/queue/:page": "queue"
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
    "lists/:type": "thumbs"
    "related/:id": "thumbs"

    "images/:image_id": "similarImages"
    ":image_id": "similarImages"

  fakeNavigate: ->
      params = window.location.hash.slice(1).split("/")
      @[params[0]](params[1] or null)

  similarArtists: (artist_name) ->
    return unless artist_name
    console.debug "Add links to similar artists"

    container = $("<div>")
      .append("<h3 style='display:inline-block'>Similar artists: </h3>")

    gm_get "https://tiuku.me/api/for-artist/#{artist_name}?session=#{app.session.id}", (data) ->
      _.each data.recommendations, (item) ->
        container.append templates.artistTag({name: item.name, url: item.link})

    $("#tag_info_box")
      .after("<hr>")
      .after(container)

    @thumbs()

  queue: (page) ->
    console.debug "Showing queue, page: #{page}"
    new MetaBarView()

    new QueueView({page: page, limit: @imagesPerPage or 21})

  thumbs:  ->
    @imagesPerPage = $(".media-box").length if @imagesPerPage is null
    console.debug("Images per page: #{@imagesPerPage}")

    if window.location.hash
      @fakeNavigate()

    else
      new MetaBarView()
      console.debug "Add queue-button to thumbnails"
      _.each $(".media-box .media-box__header"), (infoElement) ->
        new ThumbnailInfoView({el: infoElement, type: "big"})

      _.each $(".image-thumb-box.normalimage .imageinfo.normal"), (infoElement) ->
        new ThumbnailInfoView({el: infoElement, type: "normal"})

  similarImages: (image_id) ->
    return if isNaN parseInt(image_id)
    console.debug "Add list of similar images"

    target = $(".center--layout--flex")
      .after($("<div class='image-similars'>").prepend(new ImageView(imageId: image_id).el))

    target.before("<hr>")

window.QueueView = Backbone.View.extend
  el: "#imagelist_container"
  initialize: (options) ->
    @page = (options.page or 1) - 1
    @limit = options.limit or 21
    @queue = app.imageQueue.list()
    @$el.html("")
    @$el.addClass("queue-list")
    @render()

  events: ->
    "click .queue-all": "removeAll"
    "click .pagination a": "navigate"

  navigate: (event) ->
    @undelegateEvents()
    setTimeout( ->
      app.fakeNavigate()
    , 50)

  render: ->
    meta =
      light: false
      count: @queue.length
      page: @page + 1
      pages: Math.ceil(@queue.length / @limit)

    @$el.append(templates.queueMetabar(meta))
    $content = $("<div class='block__content js-resizable-media-container'></div>")
    @$el.append($content)

    queue = @queue.slice(@page * @limit, (@page + 1) * @limit)
    if queue.length > 0
      gm_get("https://derpiboo.ru/search.json?q=id%3A#{queue.join("+||+id%3A")}", (image_data) =>
        images = _.sortBy data2images(image_data), (image) ->
          queue.indexOf(image.id)
        _.each images, (image) =>
          $content.append new ThumbnailView(image: image).el
        meta.light = true
        @$el.append(templates.queueMetabar(meta))
      , (failure) =>
        console.debug("Derpibooru API failure")
        $content.append("<h2>Derpibooru API failure</h2>")
      )

    else
      $content.append("<h2>Empty queue</h2>")

  removeAll: ->
    console.debug "Removing all images from queue"
    $(".add-queue.queued").click()

window.ImageView = Backbone.View.extend
  tagName: "div"
  id: "imagelist_container"
  className: "recommender"
  initialize: (options) ->
    @isKnownImage = true
    @offset = 0
    @recommendations = []
    @image =
      id: options.imageId
      is_faved: -> $(".interaction--fave.active").length > 0
      is_upvoted: -> $(".interaction--upvote.active").length > 0
      is_downvoted: -> $(".interaction--downvote.active").length > 0
      fave: -> fakeClick($(".interaction--fave")[0])
      upvote: -> fakeClick($(".interaction--upvote")[0])
      downvote: -> fakeClick($(".interaction--downvote")[0])

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
    console.debug("Loading recommendations for #{@image.id}")

    if @isKnownImage
      tiukuAPI = "https://tiuku.me/api/for-image/#{@image.id}?session=#{app.session.id}&offset=#{@offset}"
      gm_get(tiukuAPI, (data) =>
        ids = _.filter _.map(data.recommendations, (item) -> item.id), (id) -> id isnt null
        if ids.length > 0 or @offset != 0
          @_tiukuSuccessLoad(ids)
        else
          @isKnownImage = false
          @load()
      , (fail) =>
        console.debug("Tiuku.me API failure")
        @renderFailure("Tiuku.me API failure")
      )
    else
      tags = _.map $(".tag-list .tag"), (element) -> $(element).attr("data-tag-name")
      faves =  _.map $(".interaction-user-list-item"), (element) -> element.text

      if tags.length + faves.length < 24
        return @render()

      tiukuAPI = "https://tiuku.me/api/tags/image/?session=#{app.session.id}&offset=#{@offset}"
      data =
        tags: tags.join()
        faves: faves.join()
      $.post(tiukuAPI, data, (data) =>
        ids = _.filter _.map(data.recommendations, (item) -> item.id), (id) -> id isnt null
        @_tiukuSuccessLoad(ids)
      , (fail) =>
        console.debug("Tiuku.me API failure")
        @renderFailure("Tiuku.me API failure")
      )

  _tiukuSuccessLoad: (ids) ->
    gm_get("/api/v2/images/show/?ids=#{ids.join()}", (image_data) =>
      images = _.sortBy(data2images(image_data), (image) -> ids.indexOf(image.id))
      @recommendations = @recommendations.concat(images)
      @render()
    , (fail) =>
      console.debug("Derpiboo.ru API failure")
      @renderFailure("Derpiboo.ru API failure")
    )

  renderFailure: (msg) ->
    console.debug("Rendering failure message")
    @$el
      .html(templates.similarImagesTitle())
      .append("<div>#{msg}</div>")
    return @

  render: ->
    @$el.html(templates.similarImagesTitle())
    if @recommendations.length <= 0
      console.debug("No thumbnails to render")
      @$el.append("<div>No recommendations</div>")
    else
      console.debug("Rendering thumbnails")
      _.each @recommendations, (item) =>
        hiddenTags = _.intersection(item.tag_ids, booru.hiddenTagList)
        if hiddenTags.length <= 0
          @$el.append new ThumbnailView(image: item).el
          @$el.append(" ")

      @$el.append(templates.loadMoreImage())
      @$el.append(" ")
      @$el.append(templates.nextInQueueImage())

    return @


window.ThumbnailView = Backbone.View.extend
  tagName: "div"
  className: "media-box recommender"

  events:
    "click .add-queue": "queue"

  initialize: (options) ->
    @image = options.image
    spoileredTags = _.intersection(@image.tag_ids, booru.spoileredTagList)
    # TODO Recommendation = Backbone.Model.extend ...
    _.extend @image,
      spoileredTags: spoileredTags
      # isFaved: => _.contains(@image.tags, "faved_by:#{app.session.user}")
      isSpoilered: -> spoileredTags.length > 0
      isQueued: => app.imageQueue.contains(@image.id)

    if @image.deletion_reason isnt undefined
      @renderDeleted()
    else if @image.duplicate_of isnt undefined
      @short_image = ""
      @$el.html("<div class='image-container thumb'><a href='/#{@image.duplicate_of}'>Duplicate of #{@image.duplicate_of}</a></div>")
    else
      @short_image = @image.image.replace(/__[a-z0-9+_-]+\./, ".")
      @render()

  render: ->
    @$el.attr("data-image-id", @image.id)
    @$el.html templates.thumbnail
      image: @image
      short_image: @short_image
    @$el.append(" ")

  renderDeleted: ->
    @$el.html templates.thumbnailDeleted
      image: @image
    @$el.append(" ")

  queue: ->
    console.debug("Queuing #{@image.id}")
    app.imageQueue.toggle(@image.id)
    @render()

window.ThumbnailInfoView = Backbone.View.extend
  initialize: (options) ->
    @el = options.el
    @type = options.type
    imageContainer = @$el.parent().find(".image-container")
    @link = imageContainer
      .attr("data-download-uri")
      .replace(/[/]download[/]/, "/view/")
      .replace(/__[a-z0-9+_-]+\./, ".")
    @image =
      id: parseInt(imageContainer.attr("data-image-id"))
      tags: imageContainer.attr("data-image-tag-aliases")
      score: imageContainer.attr("data-upvotes")
      faves: imageContainer.attr("data-faves")
      representations: JSON.parse(imageContainer.attr("data-uris"))
      image: @link

    @render()
    console.debug @image

  events:
    "click .add-queue": "queue"

  render: ->
    @remove() if _.isEmpty(@image)
    @$el.find(".id").remove()
    @$el.find(".add-queue").remove()

    @$el.prepend("<a href='#{@link}' class='id' title='#{@image.id}'><i class='fa fa-image'></i></a>")
    if app.imageQueue.contains(@image.id)
      @$el.append("<a class='add-queue queued'><i class='fa fa-plus-square'></i></span></a>")
    else
      @$el.append("<a class='add-queue'><i class='fa fa-plus-square'></i></span></a>")

  queue: ->
    console.debug("Queuing #{@image.id}")
    app.imageQueue.toggle(@image.id)
    @render()


window.MetaBarView = Backbone.View.extend
  el: "#imagelist_container > .block__header"
  events:
    "click .queue-all": "queueAll"

  initialize: ->
    console.debug "Initializing metabar"
    @$el.find(".flex__right").prepend(templates.queueAll())

  queueAll: ->
    console.debug "Queuing all images"
    $(".add-queue:not(.queued)").click()


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
    @queue = JSON.parse(localStorage.getItem("derpQueue") or "[]") or []

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
    # @history.unshift(nextId)
    @save()
    document.location = "/#{nextId}"

  save: ->
    console.debug("Saving queue")
    localStorage.setItem("derpQueue", JSON.stringify(@queue))
    localStorage.setItem("derpHistory", "")
    localStorage.setItem("derpCache", "")

  contains: (id) -> _.contains(@queue, id)

  list: -> _.clone(@queue)


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
    localStorage.setItem "derpQueue", null
    localStorage.setItem "derpHistory", null

  _makeId: ->
    randChar = ->
        chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return chars.charAt(Math.floor(Math.random() * chars.length))

    return _.map([1..16], randChar).join("")


window.templates = {}
window.templates.thumbnail = _.template("
<div class='media-box__header'>
    <a href='<%= short_image %>' class='id' title='<%- image.id %>'><i class='fa fa-image'></i></a>
    <a class='interaction--fave<% if (image.faved == true) {print(' active');} %>' href='#' data-image-id='<%- image.id %>'><span class='fave-span'><i class='fa fa-star'></i> <span class='favourites' data-image-id='<%- image.id %>'><%- image.faves %></span></span></a>
    <a class='interaction--upvote<% if (image.voted == 'up') {print(' active');} %>' href='#' data-image-id='<%- image.id %>'><span class='vote-up-span'><i class='fa fa-arrow-up vote-up'></i></span></a>
    <span class='score' data-image-id='<%- image.id %>'><%- image.score %></span>
    <a class='interaction--downvote<% if (image.voted == 'down') {print(' active');} %>' href='#' data-image-id='<%- image.id %>'><span class='vote-down-span'><i class='fa fa-arrow-down' title='neigh'></i></a>
    <a href='/<%= image.id %>#comments' class='interaction--comments'><i class='fa fa-comments'></i></a>

    <% if (image.isQueued()) { %>
    <a class='add-queue queued'%><i class='fa fa-plus-square'></i></a>
    <% } else { %>
    <a class='add-queue'><i class='fa fa-plus-square'></i></a>
    <% } %>
</div>
<div class='media-box__content center--flex-hv media-box__content--large'>
    <div class='image-container thumb'><a href='/<%= image.id %>'><% if (image.isSpoilered()) { print(image.tags.join(', ')); } else { %><img src='<%= image.representations.thumb %>' /><% } %></a></div>
</div>
")

window.templates.thumbnailDeleted = _.template("
<div class='media-box__header'>
    <span><%- image.id %></span>
</div>
<div class='image-container thumb'><span><%- image.deletion_reason %></span></div>
")

window.templates.nextInQueueImage = _.template("
<div class='image-thumb-box bigimage recommender next-in-queue'>
    <div class='imageinfo normal spacer'></div>
    <div class='image-container thumb'>
        <a>Next in queue <i class='fa fa-arrow-right'></i></a>
    </div>
</div>
")

window.templates.loadMoreImage = _.template("
<div class='image-thumb-box bigimage recommender load-more'>
    <div class='imageinfo normal spacer'></div>
    <div class='image-container thumb load-more-inner'>
        <a>Load more</a>
    </div>
</div>
")

window.templates.nextInQueueBar = _.template("
<div class='image-thumb-box bigimage recommender next-in-queue next-in-queue-bar'>
    <div><a>Next in queue <i class='fa fa-arrow-right'></i></a></div>
</div>
")

window.templates.loadMoreBar = _.template("
<div>
    <div class='load-more-inner'>
        <a>Load more</a>
    </div>
</div>
")

window.templates.similarImagesTitle = _.template("
<div id='similars-title'>
    <h6>Similar Images</h6>
</div>
")

window.templates.artistTag = _.template("
<span class='tag tag-ns-artist'>
    <a href='<%= url %>'><%- name %></a>
</span>
")

window.templates.queueAll = _.template("
<a class='queue-all' title='Queue all images on page'>
    <i class='fa fa-cloud-download'></i>
    <span class='hide-mobile'>Queue All</span>
</a>
")

window.templates.queueMetabar = _.template("
<div class='block__header flex'>
    <span class='block__header__title hide-mobile'>Queue of <%- count %> images</span>
    <nav class='pagination'>
        <% if (page > 1) { %>
        <a href='/images/#queue/'>« First</a>
        <span class='prev'><a href='/images/#queue/<% print(page - 1) %>'>‹ Prev</a></span>
        <% } if (page > 5) { %>
        <span class='page gap'>…</span>
        <% } for (var i = Math.max(page - 4, 1); i < page; i++) { %>
        <a class='page' href='/images/#queue/<%- i %>'><%- i %></a>
        <% } if (pages > 1) { %>
        <span class='page-current'><%- page %></span>
        <% } for (var i = page + 1; i < page + 5 && i <= pages; i++) { %>
        <a class='page' href='/images/#queue/<%- i %>'><%- i %></a></span>
        <% } if (page + 5 < pages) { %>
        <span class='page gap'>…</span>
        <% } if (pages > 1 && page < pages) { %>
        <span class='next'><a href='/images/#queue/<% print(page + 1) %>'>Next</a></span>
        <a href='/images/#queue/'>Last</a>
        <% } %>
    </nav>
    <div class='flex__right'>
        <a class='queue-all' title='Remove all images from queue'>
            <i class='fa fa-cloud-download'></i>
            <span class='hide-mobile'>Remove All</span>
        </a>
    </div>
</div>
")

# Userscripts do not seem to allow loading other than javascript files.
# I'll just inject the CSS straight into <head>


$("head").append("
<style type='text/css'>

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
.id {
    margin-right: 2px;
    padding-left: 2px;
    padding-right: 2px;
}
.id:hover {
    color: white;
    background: #57a4db;
}

.add-queue {
    margin-left: 2px;
}
.add-queue {
    cursor: pointer;
}
.add-queue.queued, .add-queue:hover{
    background: #57a4db;
    color: white;
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

.queue-all {
    cursor: pointer;
}
</style>")
#READY.

window.runDerpibooruExplorer = (config) ->
  #RUN

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
