# Nuthatch

Nuthatch is a single-user web publishing app that is based upon:

* Lua
* FastCGI with Nginx
* CouchDB
* Elasticsearch
* Mustache
* REST API
* Markdown
* Mailgun
* optionally uses Memcached
* optionally uses Redis

Test website: <http://nuthatch.soupmode.com>

API endpoint: <http://nuthatch.soupmode.com/api/v1>

Nuthatch functions nearly identical to my Veery web pub apps. I created versions of Veery in Perl and Node.js. 

[API documentation](https://github.com/jrsawvel/Veery-API-Perl/blob/master/docs/veery-api.md)

On the homepage, Nuthatch displays a stream of posts, ordered youngest to oldest by created or updated date, which is similar to my Scaup and Veery web pub apps, 

When logged in, a small textarea box exists at the top of the homepage, making it easy to create quick notes or articles. The author does not need to leave the homepage. 

A link to a larger textarea box exists. I need to add support for my Tanager JavaScript editor.

Pages can be cached in Redis or Memcached. My Nginx install contains the Memcached module but not the Redis module. For logged-in users, if the page is cached, then Nginx pulls it from Memcached, and my Lua code is not touched. 

If the page was not cached, then my Lua code gets executed, and it pulls the content from CouchDB, applies the template, and dynamically creates the HTML page to be served. My code also caches the page. A refresh gets the cached version.

Since I don't have the Redis module compiled into my Nginx install, the Lua code gets executed, and my code checks Redis for the cached content. If the content exists in Redis, then the Lua code serves it up. 

I started with this Redis setup because the Memcached module for Lua did not work. The Memcached module was last updated in 2010. I [created my own version](https://github.com/jrsawvel/lua-memcached-mods) of the Lua Memcached module that was based upon the old version.

I could have rebuilt Nginx to include the Redis module.

Posts in Nuthatch can be deleted and undeleted. 

The only non-HTML markup that Nuthatch supports is Markdown. My other web pub apps generally support Markdown, MultiMarkdown, Textile, and my own custom formatting commands.

Login is done by entering only an email address. If the address matches what's contained within the YAML config file, then a link with session info is emailed to that address. Clicking the link that's contained within the email message will login the user.


---

Repo cleanup to-do:


* in the API directory, remove session.lua. the code in the original file has been split out into multiple smaller modules with different names: login, auth, and logout.
* in the Shared directory, remove the accidental file .lua.
