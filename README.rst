======
README
======

TOC
---
1. Changelog
2. Introduction
3. Requirements
4. Install
5. Features
6. Known Issues
7. Privacy Policy
8. License

Changelog
---------
v1.5.4  - Fix for recent derpibooru API change

v1.5.3  - Fix for changed derpibooru styling

v1.5.2  - Handle changes in interactions API and window.booru

v1.5.1  - Add queue navigation to native /related/ list

v1.5.0  - POST image data if no recommendations can be made with cached data. This allows making recommendations if there are 24 or more tags and faves combined.

v1.4.2  - Update changed css class names

v1.4.1  - Fix error some handling, layout of tag cloud

v1.4.0  - Enable voting from thumbnails, handle deleted similar images.

v1.3.1  - Don't hardcode the derpiboo.ru domain.

v1.3.0  - Refactor how APIs are used, paginated queue view.

v1.2.1  - Use derpibooru api to fetch fave and vote info for recommendation thumbnails. Removed stars altogether.

v1.2.0  - Add view for inspecting current queue.

v1.1.7  - Add thumbnail enhancements to /lists/:splat urls and "Queue All" button to imagelists.

v1.1.6  - Add and remove significant whitespaces to work with new styling

v1.1.5  - Configuration option to remove stars

v1.1.4  - Add to queue button toggles item in queue instead of adding

v1.1.3  - Bugfix for keyboard faving

v1.1.2  - Removes 'Q' from small thumbnails, short filenames for download links.

v1.1.1  - Direct image link in thumnbail frames, support small thumbnails

v1.1.0  - Highlights, festive hats and privacy policy changes.

Highlights can be accessed from the top-right menu and contains the newest images in derpibooru with only images that current user might like.

Privacy policy was changed as highlights require username for user specific filtering. Username is only sent as part of query if this feature is used.

Hats for christmas holiday (can be disabled from config)!

v1.0.0  - Initial release


Introduction
------------
The aim of this project is to make finding new quality images on derpiboo.ru easier and more fun. This is achieved by providing recommendations depending on user's context and by enchancing derpiboo.ru user experience with navigational improvements and visual notifications.

Preview video: https://www.youtube.com/watch?v=0tmffdFo3v8

Currently recommendations are:
 - Images that are similar to current image based on tags and faves of images
 - Artists that are similar to current artist based on tags and faves of each artist's images
 - Highlights: newest images that are similar to current users profile

Similarity and recommendation are often different things but as for v1.0 the recommendations are just sorted by similarity.

Navigational improvements consist of adding keyboard navigation, a queue for images and visial notifications. The queue is useful for avoiding opening dozens of browser tabs while browsing through recommendations.


Requirements
------------
Chrome + Tampermonkey
or
Firefox + Greasemonkey


Install
-------
https://tiuku.me/static/Derpibooru_Explorer.user.js


Features
--------
This userscript adds queue navigation, similar images search, similar artists search, newest images that user might like, some keyboard shortcuts and visual notifications to derpiboo.ru. User can also gain stars when something special happens.

User can add images to queue from image thumbnails and navigate to the next image in the queue by pressing 'e'.

When viewing a single image user is given thumbnails of images that are similar to current image. Spoilered tags and hided tags are spoilered and hided. More similar images may be fetched using a provided button.

When viewing an artist tag image listing the user gets a list of similar artists.

User can access highlighted images from top-right menu. This view contains newest images that are similar to users profile.

When viewing a single image user can press '1', '2' or '3' to toggle fave, upvote or downvote respectively on current image. A visual notification is displayed.


Known Issues
------------
Dataset is not realtime and most updates to it are only partial.
 - Recommendation list may show thumbnails as not faved even when they are faved.
 - Newest images won't get any similar images and won't show up in similar images lists. Same applies to artist similarity.
 - Images with really low number of faves won't get similar images or show up on similar images list.

Recommendations list doesn't provide all the derpiboo.ru functionality.
 - No faves, upvotes or downvotes from thumbnail buttons.
 - Whether current user has upvoted or downvoted is not displayed in the thumbnail as this data is not public.
 - Number of comments is not displayed in the recommendations list due to processing costs.
 - Spoilers display a list of spoilered tags instead of image spoiler.
 - Images behind spoilers cannot be inspected with mouse hover or click.

Keyboard shortcuts do not gurantee that the action was succesful
 - The notification is displayed even if the action fails.

Highlights could be better
 - No pagination.
 - Might not work well if user has low number of faves.
 - Update only every few days


Privacy Policy
--------------
Recommendations are based on public data fetched from derpiboo.ru API and on performance data collected from users of tiuku.me API.

All users are given a session token. This token, along with requests and responses related to it, are saved by tiuku.me and are used for evaluating and improving tiuku.me service.

Session tokens expires when user logs in, logs out or is logged out automatically. User's local storage is used for storing session token and username to provide this functionality.

Local storage is also used for storing other state information of this script, like the state of the image queue.

Highlights feature uses current users username as query. Otherwise this script does not send usernames, user_ids, passwords or other personal information to tiuku.me or 3rd party services. Hiding, spoilering and showing favourites is done purely on client side and is based on public data from derpiboo.ru API and derpiboo.ru page that the user is currently viewing.

All assets are downloaded from tiuku.me over a secure connection and the main script "derpibooru_explorer.js" makes secure queries to tiuku.me to fetch recommendations. No requests are made to 3rd party services.
