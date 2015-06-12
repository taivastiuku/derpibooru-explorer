// Generated by CoffeeScript 1.9.1

/** @license
 * Derpibooru Explorer
 * Copyright (C) 2014 taivastiuku@gmail.com
#
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or any later version.
#
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
#
 * https://www.gnu.org/licenses/gpl-2.0.html
#
 * Source for this file can be found at:
 * https://tiuku.me/static/derpibooru_explorer.coffee
 */
"use strict";
var ImageQueue, Session, app, booru, hatStyles, inputSelected, videoModeStyles;

app = null;

booru = unsafeWindow.booru;

inputSelected = function() {
  var ref;
  return (ref = document.activeElement.tagName) === "INPUT" || ref === "TEXTAREA";
};

window.Router = Backbone.Router.extend({
  initialize: function(config) {
    console.debug("Initializing router");
    this.config = config;
    this.session = new Session(config.LOGOUT_ENDS_SESSION);
    this.imageQueue = new ImageQueue();
    $($(".dropdown_menu")[0]).append("<a href='/images/?highlights'><i class='fa fa-fw fa-birthday-cake'></i> Highlights</a> <a href='/images/?queue'><i class='fa fa-cloud-download'></i> Queue</a>");
    KeyboardJS.on("e", (function(_this) {
      return function() {
        console.debug("Next in queue");
        if (!inputSelected()) {
          return _this.imageQueue.next();
        }
      };
    })(this));
    return console.debug("Router initialized");
  },
  routes: {
    "tags/artist-colon-:artist_name": "similarArtists",
    "": "thumbs",
    "tags/:tag": "thumbs",
    "search": "thumbs",
    "search/": "thumbs",
    "search/index": "thumbs",
    "images": "thumbs",
    "images/": "thumbs",
    "images/favourites": "thumbs",
    "images/favourites/:page": "thumbs",
    "images/upvoted": "thumbs",
    "images/upvoted/:page": "thumbs",
    "images/uploaded": "thumbs",
    "images/uploaded/:page": "thumbs",
    "images/watched": "thumbs",
    "images/watched/:page": "thumbs",
    "images/page/": null,
    "images/page/:page": "thumbs",
    "lists/:type": "thumbs",
    "images/:image_id": "similarImages",
    ":image_id": "similarImages",
    "art/*path": "forum",
    "pony/*path": "forum",
    "writing/*path": "forum",
    "dis/*path": "forum",
    "rp/*path": "forum",
    "meta/*path": "forum"
  },
  similarArtists: function(artist_name) {
    var container;
    if (!artist_name) {
      return;
    }
    console.debug("Add links to similar artists");
    container = $("<div>").append("<h3 style='display:inline-block'>Similar artists: </h3>");
    $.get("https://tiuku.me/api/for-artist/" + artist_name + "?session=" + app.session.id, function(data) {
      return _.each(data.recommendations, function(item) {
        return container.append(templates.artistTag({
          name: item.name,
          url: item.link
        }));
      });
    });
    $("#tag_info_box").after("<hr>").after(container);
    return this.thumbs();
  },
  thumbs: function() {
    new MetaBarView();
    if (window.location.search.indexOf("?highlights") > -1) {
      console.debug("Getting recommendations");
      return new HighlightsView({
        user: app.session.user
      });
    } else if (window.location.search.indexOf("?queue") > -1) {
      console.debug("Showing queue");
      return new QueueView();
    } else {
      console.debug("Add queue-button to thumbnails");
      _.each($(".image.bigimage .imageinfo.normal"), function(infoElement) {
        return new ThumbnailInfoView({
          el: infoElement,
          type: "big"
        });
      });
      return _.each($(".image.normalimage .imageinfo.normal"), function(infoElement) {
        return new ThumbnailInfoView({
          el: infoElement,
          type: "normal"
        });
      });
    }
  },
  similarImages: function(image_id) {
    var target;
    if (isNaN(parseInt(image_id))) {
      return;
    }
    console.debug("Add list of similar images");
    target = $(".image_show_container").after(new ImageView({
      imageId: image_id
    }).el);
    if (app.config.VIDEO_MODE) {
      $("img#image_display").on("load", function() {
        var height;
        height = $(".image_show_container").height();
        return $("#imagelist_container.recommender").height(height - 3);
      });
    } else {
      target.before("<hr>");
    }
    if (app.config.HATS) {
      return setTimeout(function() {
        var day, month, today;
        today = new Date();
        month = today.getUTCMonth() + 1;
        day = today.getUTCDate();
        if (month === 12 && day > 21 && day < 27) {
          return $(".post-avatar").append("<img class='hat-comment' src='https://tiuku.me/static/pic/jul.gif'>");
        }
      }, 3500);
    }
  },
  forum: function(path) {
    var day, month, today;
    if (app.config.HATS) {
      today = new Date();
      month = today.getUTCMonth() + 1;
      day = today.getUTCDate();
      if (month === 12 && day > 21 && day < 27) {
        return $(".post-avatar").append("<img class='hat' src='https://tiuku.me/static/pic/jul.gif'>");
      }
    }
  }
});

window.QueueView = Backbone.View.extend({
  el: "#imagelist_container",
  initialize: function(options) {
    this.$el.html("");
    this.$el.addClass("queue-list");
    return this.render();
  },
  events: function() {
    return {
      "click .queue-all": "removeAll"
    };
  },
  render: function() {
    var queue;
    queue = app.imageQueue.list();
    this.$el.append(templates.queueMetabar({
      count: queue.length
    }));
    if (queue.length > 0) {
      return _.each(queue, (function(_this) {
        return function(item) {
          var image;
          image = app.imageQueue.loadImage(item);
          return _this.$el.append(new ThumbnailView({
            image: image
          }).el);
        };
      })(this));
    } else {
      return this.$el.append("<h2>Empty queue</h2>");
    }
  },
  removeAll: function() {
    console.debug("Removing all images from queue");
    return $(".add-queue.queued").click();
  }
});

window.HighlightsView = Backbone.View.extend({
  el: "#imagelist_container",
  initialize: function(options) {
    this.$el.html("");
    this.$el.addClass("highlights");
    this.offset = 0;
    this.highlights = [];
    this.user = options.user;
    return this.load();
  },
  events: {
    "click .recommender.load-more": "loadMore"
  },
  load: function() {
    return $.get("https://tiuku.me/api/highlights/" + this.user + "?session=" + app.session.id + "&offset=" + this.offset, (function(_this) {
      return function(data) {
        _this.highlights = _this.highlights.concat(data.recommendations);
        return _this.render();
      };
    })(this)).fail((function(_this) {
      return function() {
        console.debug("Server error");
        return _this.$el.append("<h1>Server error</h1>");
      };
    })(this));
  },
  render: function() {
    this.$el.html("<div class='metabar'><div class='metasection'><strong>Highlighted images for " + this.user + "</srong></div></div>");
    _.each(this.highlights, (function(_this) {
      return function(item) {
        var hiddenTags;
        hiddenTags = _.intersection(item.tags, booru.hiddenTagList);
        if (hiddenTags.length <= 0) {
          return _this.$el.append(new ThumbnailView({
            image: item
          }).el);
        }
      };
    })(this));
    return this.$el.append(templates.loadMoreImage());
  },
  loadMore: function(event) {
    $(event.target).remove();
    this.offset = this.highlights.length > 0 ? this.highlights.slice(-1)[0]["id_number"] : 0;
    return this.load();
  }
});

window.ImageView = Backbone.View.extend({
  tagName: "div",
  id: "imagelist_container",
  className: "recommender",
  initialize: function(options) {
    this.offset = 0;
    this.recommendations = [];
    this.image = {
      id_number: options.imageId,
      is_faved: function() {
        return $(".fave_link.faved").length > 0;
      },
      is_upvoted: function() {
        return $(".vote_up_link.voted_up").length > 0;
      },
      is_downvoted: function() {
        return $(".vote_down_link.voted_down").length > 0;
      },
      fave: function() {
        return $($(".favourites")[0]).click();
      },
      upvote: function() {
        return $($(".upvote-span")[0]).click();
      },
      downvote: function() {
        return $($(".downvote-span")[0]).click();
      }
    };
    KeyboardJS.on("1", (function(_this) {
      return function(event) {
        console.debug("fave");
        if (!inputSelected()) {
          new NotificationView({
            fa: "fa-star",
            off: _this.image.is_faved()
          });
          return _this.image.fave();
        }
      };
    })(this));
    KeyboardJS.on("2", (function(_this) {
      return function(event) {
        console.debug("upvote");
        if (!inputSelected()) {
          new NotificationView({
            fa: "fa-arrow-up",
            off: _this.image.is_upvoted()
          });
          return _this.image.upvote();
        }
      };
    })(this));
    KeyboardJS.on("3", (function(_this) {
      return function(event) {
        console.debug("downvote");
        if (!inputSelected()) {
          new NotificationView({
            fa: "fa-arrow-down",
            off: _this.image.is_downvoted()
          });
          return _this.image.downvote();
        }
      };
    })(this));
    return this.load();
  },
  events: {
    "click .recommender.load-more": "loadMore",
    "click .recommender.next-in-queue": function() {
      return app.imageQueue.next();
    }
  },
  loadMore: function(event) {
    $(event.target).remove();
    this.offset += 8;
    return this.load();
  },
  load: function() {
    return $.get("https://tiuku.me/api/for-image/" + this.image.id_number + "?session=" + app.session.id + "&offset=" + this.offset, (function(_this) {
      return function(data) {
        var ids;
        ids = _.map(_.filter(data.recommendations, function(item) {
          return item.id !== null;
        }), function(item) {
          return item.id;
        });
        return $.get("https://derpiboo.ru/api/v2/interactions/interacted.json?class=Image&ids=" + (ids.join()), function(raw_interactions) {
          var interactions;
          interactions = {};
          _.each(raw_interactions, function(i) {
            var obj;
            obj = interactions[i.interactable_id] || {};
            if (i.interaction_type === "faved") {
              obj.faved = true;
            } else if (i.interaction_type === "voted") {
              obj.voted = i.value;
            }
            return interactions[i.interactable_id] = obj;
          });
          _.each(data.recommendations, function(r) {
            var interaction;
            interaction = interactions[r.id];
            if (interaction) {
              return _.extend(r, interaction);
            }
          });
          _this.recommendations = _this.recommendations.concat(data.recommendations);
          return _this.render();
        }).fail(function() {
          this.recommendations = this.recommendations.concat(data.recommendations);
          return this.render();
        });
      };
    })(this)).fail(function() {
      console.debug("Server error");
      return this.renderFailure();
    });
  },
  renderFailure: function() {
    console.debug("Rendering failure message");
    this.$el.html(templates.similarImagesTitle()).append("<div>Data load error</div>");
    return this;
  },
  render: function() {
    this.$el.html(templates.similarImagesTitle());
    if (this.recommendations.length <= 0) {
      console.debug("No thumbnails to render");
      this.$el.append("<div>No recommendations</div>");
    } else {
      console.debug("Rendering thumbnails");
      _.each(this.recommendations, (function(_this) {
        return function(item) {
          var hiddenTags;
          hiddenTags = _.intersection(item.tags, booru.hiddenTagList);
          if (hiddenTags.length <= 0) {
            _this.$el.append(new ThumbnailView({
              image: item
            }).el);
            return _this.$el.append(" ");
          }
        };
      })(this));
      if (app.config.VIDEO_MODE === true) {
        this.$el.append(templates.loadMoreBar());
        this.$el.append(templates.nextInQueueBar());
      } else {
        this.$el.append(templates.loadMoreImage());
        this.$el.append(" ");
        this.$el.append(templates.nextInQueueImage());
      }
    }
    return this;
  }
});

window.ThumbnailView = Backbone.View.extend({
  tagName: "div",
  className: "image bigimage recommender",
  events: {
    "click .add-queue": "queue"
  },
  initialize: function(options) {
    var spoileredTags;
    this.image = options.image;
    spoileredTags = _.intersection(this.image.tags, booru.spoileredTagList);
    _.extend(this.image, {
      spoileredTags: spoileredTags,
      isSpoilered: function() {
        return spoileredTags.length > 0;
      },
      isQueued: (function(_this) {
        return function() {
          return app.imageQueue.contains(_this.image.id_number);
        };
      })(this)
    });
    this.short_image = this.image.image.replace(/__[a-z0-9+_-]+\./, ".");
    return this.render();
  },
  render: function() {
    this.$el.html(templates.thumbnail({
      image: this.image,
      short_image: this.short_image
    }));
    return this.$el.append(" ");
  },
  queue: function() {
    app.imageQueue.toggle(this.image.id_number, this.image);
    return this.render();
  }
});

window.ThumbnailInfoView = Backbone.View.extend({
  initialize: function(options) {
    var parent;
    this.el = options.el;
    this.type = options.type;
    parent = this.$el.parent();
    this.link = parent.attr("data-download-uri").replace(/[\/]download[\/]/, "/view/").replace(/__[a-z0-9+_-]+\./, ".");
    this.image = {
      id: parent.attr("data-image-id"),
      id_number: parseInt(this.$el.find(".comments_link").attr("href").split("#")[0].slice(1)),
      tags: parent.attr("data-image-tag-aliases"),
      score: parent.attr("data-upvotes"),
      favourites: parent.attr("data-faves"),
      thumb: JSON.parse(parent.attr("data-uris")).thumb,
      image: this.link
    };
    return this.render();
  },
  events: {
    "click .add-queue": "queue"
  },
  render: function() {
    if (_.isEmpty(this.image)) {
      this.remove();
    }
    this.$el.find(".add-queue").remove();
    this.$el.find(".id_number").remove();
    if (this.type === "big") {
      this.$el.prepend("<a href='" + this.link + "' class='id_number' title='" + this.image.id_number + "'><i class='fa fa-image'></i> " + this.image.id_number + "</a>");
      if (app.imageQueue.contains(this.image.id_number)) {
        return this.$el.append("<span class='add-queue queued'%><a><i class='fa fa-plus-square'></i> in queue</a></span>");
      } else {
        return this.$el.append("<span class='add-queue'><a><i class='fa fa-plus-square'></i> Queue</a></span>");
      }
    } else if (this.type === "normal") {
      this.$el.prepend("<a href='" + this.link + "' class='id_number' title='" + this.image.id_number + "'><i class='fa fa-image'></i></a>");
      if (app.imageQueue.contains(this.image.id_number)) {
        return this.$el.append("<span class='add-queue queued'%><a><i class='fa fa-plus-square'></i></a></span>");
      } else {
        return this.$el.append("<span class='add-queue'><a><i class='fa fa-plus-square'></i></a></span>");
      }
    }
  },
  queue: function() {
    app.imageQueue.toggle(this.image.id_number, this.image);
    return this.render();
  }
});

window.MetaBarView = Backbone.View.extend({
  el: "#imagelist_container > .metabar",
  events: {
    "click .queue-all": "queueAll"
  },
  initialize: function() {
    console.debug("Initializing metabar");
    return this.$el.find(".othermeta").prepend(templates.queueAll());
  },
  queueAll: function() {
    console.debug("Queuing all images");
    return $(".add-queue:not(.queued)").click();
  }
});

window.NotificationView = Backbone.View.extend({
  tagName: "div",
  className: "over-notify",
  initialize: function(options) {
    if (options.fa === void 0) {
      return;
    }
    this.$el.append($("<span class='fa " + options.fa + " " + (options.off === true ? "off" : "") + "'>"));
    $("#content").append(this.el);
    return setTimeout((function(_this) {
      return function() {
        return _this.$el.fadeOut("fast", function() {
          return _this.remove();
        });
      };
    })(this), 1000);
  }
});

ImageQueue = (function() {
  function ImageQueue() {
    console.debug("Initializing queue");
    this.load();
    this.actionCalled = false;
  }

  ImageQueue.prototype.load = function() {
    this.queue = JSON.parse(localStorage.getItem("derpQueue")) || [];
    this.history = JSON.parse(localStorage.getItem("derpHistory")) || [];
    return this.imageCache = JSON.parse(localStorage.getItem("derpCache")) || {};
  };

  ImageQueue.prototype.add = function(id, image) {
    id = parseInt(id);
    if (isNaN(id)) {
      return;
    }
    console.debug("Adding #" + id + " to queue");
    this.load();
    new NotificationView({
      fa: "fa-cloud-download"
    });
    this.queue.push(id);
    if (image) {
      this.imageCache[id] = image;
    }
    return this.save();
  };

  ImageQueue.prototype.remove = function(id) {
    id = parseInt(id);
    if (isNaN(id)) {
      return;
    }
    console.debug("Removing #" + id + " to queue");
    this.load();
    new NotificationView({
      fa: "fa-cloud-download",
      off: true
    });
    this.queue = _.filter(this.queue, function(queue_id) {
      return queue_id !== id;
    });
    delete this.imageCache[id];
    return this.save();
  };

  ImageQueue.prototype.toggle = function(id, image) {
    id = parseInt(id);
    if (isNaN(id)) {
      return;
    }
    console.debug("Toggling #" + id);
    this.load();
    if (_.contains(this.queue, id)) {
      return this.remove(id);
    } else {
      return this.add(id, image);
    }
  };

  ImageQueue.prototype.next = function() {
    var nextId;
    new NotificationView({
      fa: "fa-arrow-right"
    });
    this.load();
    nextId = this.queue.shift();
    if (nextId === void 0 || this.actionCalled) {
      return;
    }
    this.actionCalled = true;
    console.debug("Moving to next: #" + nextId);
    this.history.unshift(nextId);
    delete this.imageCache[nextId];
    this.save();
    return document.location = "/" + nextId;
  };

  ImageQueue.prototype.save = function() {
    console.debug("Saving queue");
    localStorage.setItem("derpQueue", JSON.stringify(this.queue));
    localStorage.setItem("derpHistory", JSON.stringify(this.history));
    return localStorage.setItem("derpCache", JSON.stringify(this.imageCache));
  };

  ImageQueue.prototype.contains = function(id) {
    return _.contains(this.queue, id);
  };

  ImageQueue.prototype.list = function() {
    return _.clone(this.queue);
  };

  ImageQueue.prototype.loadImage = function(id) {
    if (this.imageCache[id]) {
      return this.imageCache[id];
    } else {
      return {
        tags: [],
        id_number: id,
        short_image: "",
        score: NaN,
        favourites: NaN,
        thumb: "",
        image: ""
      };
    }
  };

  return ImageQueue;

})();

Session = (function() {
  function Session(logoutEndsSession) {
    var oldID, oldUser;
    this.logoutEndsSession = logoutEndsSession != null ? logoutEndsSession : true;
    console.debug("Initializing session");
    this.user = booru.userName;
    oldID = localStorage.getItem("derpSession");
    oldUser = localStorage.getItem("derpUser");
    if (this.user !== oldUser && this.logoutEndsSession === true) {
      console.debug("User changed: " + oldUser + " -> " + this.user);
      this.newSession();
    } else if (oldID === null) {
      console.debug("No session id: New Session");
      this.newSession();
    } else {
      console.debug("Continue session");
      this.id = oldID;
    }
  }

  Session.prototype.newSession = function() {
    this.id = this._makeId();
    localStorage.setItem("derpSession", this.id);
    localStorage.setItem("derpUser", this.user);
    localStorage.setItem("derpQueue", null);
    return localStorage.setItem("derpHistory", null);
  };

  Session.prototype._makeId = function() {
    var randChar;
    randChar = function() {
      var chars;
      chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
      return chars.charAt(Math.floor(Math.random() * chars.length));
    };
    return _.map([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], randChar).join("");
  };

  return Session;

})();

window.templates = {};

window.templates.thumbnail = _.template("<div class='imageinfo normal'> <span> <a href='<%= short_image %>' class='id_number' title='<%- image.id_number %>'><i class='fa fa-image'></i> <%- image.id_number %></a> <span class='fave-span<% if (image.faved == true) {print('-faved');} %>'><i class='fa fa-star'></i> <span class='favourites'><%- image.favourites %></span></span> <span class='vote-up-span<% if (image.voted == 'up') {print('-up-voted');} %>'><i class='fa fa-arrow-up vote-up'></i></span> <span class='score'><%- image.score %></span> <a href='/<%= image.id_number %>#comments' class='comments_link'><i class='fa fa-comments'></i></a> <% if (image.isQueued()) { %> <span class='add-queue queued'%><a><i class='fa fa-plus-square'></i> in queue</a></span> <% } else { %> <span class='add-queue'><a><i class='fa fa-plus-square'></i> queue</a></span> <% } %> </span> </div> <div class='image_container thumb'><a href='/<%= image.id_number %>'><% if (image.isSpoilered()) { print(image.spoileredTags.join(', ')); } else { %><img src='<%= image.thumb %>' /><% } %></a></div>");

window.templates.nextInQueueImage = _.template("<div class='image bigimage recommender next-in-queue'> <div class='imageinfo normal spacer'></div> <div class='image_container thumb'> <a>Next in queue <i class='fa fa-arrow-right'></i></a> </div> </div>");

window.templates.loadMoreImage = _.template("<div class='image bigimage recommender load-more'> <div class='imageinfo normal spacer'></div> <div class='image_container thumb'> <a>Load more</a> </div> </div>");

window.templates.nextInQueueBar = _.template("<div class='image bigimage recommender next-in-queue next-in-queue-bar'> <div><a>Next in queue <i class='fa fa-arrow-right'></i></a></div> </div>");

window.templates.loadMoreBar = _.template("<div class='image bigimage recommender load-more load-more-bar'> <div> <a>Load more</a> </div> </div>");

window.templates.similarImagesTitle = _.template("<div id='similars-title'> <h6>Similar Images</h6> </div>");

window.templates.artistTag = _.template("<span class='tag tag-ns-artist'> <a href='<%= url %>'><%- name %></a> </span>");

window.templates.queueAll = _.template("<a class='queue-all' title='Queue all images on page'> <i class='fa fa-cloud-download'></i> <span class='hide-mobile'>Queue All</span> </a>");

window.templates.queueMetabar = _.template("<div class='metabar meta-table'> <div class='metasection'><strong>Queue of <%- count %> images</strong></div> <div class='othermeta'> <a class='queue-all' title='Remove all images from queue'> <i class='fa fa-cloud-download'></i> <span class='hide-mobile'>Remove All</span> </a> </div> </div>");

videoModeStyles = "<style type='text/css'> .image_show_container { width: 720px; display: inline-block; } #imagelist_container.recommender { display: inline-block; width: 528px; height: 720px; overflow-y: scroll; vertical-align: top; #image_display { max-width: 100%; height: auto; } </style>";

$("head").append("<style type='text/css'> .image-warning, #imagespns { float: left; } .over-notify { border-radius: 5px; padding: 10px; position: fixed; right: 37%; top: 10px; line-height: 100px; width: 120px; height: 120px; font-size: 120px; text-align: center; background-color: rgba(90, 90, 90, 0.3); } .over-notify .fa.off { color: black; } .over-notify .fa-star { color: gold; } .over-notify .fa-arrow-up { color: #67af2b; } .over-notify .fa-arrow-down { color: #cf0001; } .over-notify .fa-arrow-right, .over-notify .fa-cloud-download { color: DeepPink; } .recommender .fave-span { color: #c4b246; } .recommender .fave-span-faved { display: inline!important; color: white!important; background: #c4b246!important; } .recommender .vote-up-span { color: #67af2b; } .recommender .vote-up-span-up-voted { display: inline!important; color: white!important; background: #67af2b!important; } .recommender .vote-down { color: #cf0001; } .recommender.load-more-bar.bigimage.image, .recommender.next-in-queue-bar.bigimage.image { width: 506px; } .recommender.next-in-queue-bar.bigimage.image { margin-bottom: 600px; } .recommender.load-more-bar div, .recommender.next-in-queue-bar div { width: 100%; height: 100%; text-align: center; line-height: 50px; } .recommender.load-more a, .recommender.next-in-queue a { cursor: pointer; } .imageinfo.normal.spacer { height: 12px; } .id_number { margin-right: 2px; padding-left: 2px; padding-right: 2px; } .id_number:hover { color: white; background: #57a4db; } .add-queue { margin-left: 2px; padding: 0 2px; } .add-queue a { cursor: pointer; } .add-queue.queued, .add-queue:hover{ background: #57a4db; } .add-queue.queued a, .add-queue a:hover { color: white!important; } #similars-title h2 { display: inline-block; } #similars-title .fa-star { color: gold; cursor: help; } .highlights .image.recommender, .queue-list .image.recommender { margin-left: 5px; } ::selection { background: pink; } </style>");

hatStyles = "<style type='text/css'> .post, .post-meta { overflow: visible!important; } .post-avatar { position: relative; } .hat { position: absolute; top: -100px; left: -26px; } .hat-comment { position: absolute; top: -36px; left: -4px; transform: scale(1.28, 1.28); } .queue-all { cursor: pointer; } </style>";

window.runDerpibooruExplorer = function(config) {
  if (config.VIDEO_MODE === true) {
    $("head").append(videoModeStyles);
    $(document).scrollTop(90);
  }
  if (config.HATS === true) {
    $("head").append(hatStyles);
  }
  if (config.DEBUG === false) {
    console.debug = function() {};
  }
  if (config.KEYBOARD_SHORTCUTS === false) {
    KeyboardJS.on = function() {};
  }
  console.debug("Starting Derpibooru Explorer");
  app = new Router(config);
  Backbone.history.start({
    pushState: true,
    hashChange: false
  });
  return console.debug("Derpibooru Explorer started");
};
