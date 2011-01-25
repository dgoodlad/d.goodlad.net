# [d.goodlad.net](http://d.goodlad.net/) Sources

This is the source to [David Goodlad's personal website](http://d.goodlad.net).

I'm making this source available for anyone who's interested to see a sample nanoc-managed site in action. I use markdown (rdiscount) for most of my written work, and compass-susy/sass to style my pages.

## Setup

To build the site yourself, and play around, you'll need to have Ruby 1.9.2 (It may work on 1.8.7, but no guarantees!), rubygems, and bundler. Then:

    $ bundle install
    Fetching source index from ... [snip]

    $ guard

This will fire up Guard, which will watch for any file changes and recompile the site. I like it better than the built-in nanoc autocompiler, since it's a lot more flexible and seems to be more accurate. Pressing Ctrl-\ will force guard to recompile the site, which is a good thing to do when you first clone the project.

You'll probably want to run a simple webserver locally to serve up pages; I use Python's `SimpleHTTPServer` library to do so, since there doesn't seem to be anything like this available in Ruby-land:

    $ python -m SimpleHTTPServer

You'll now have access to your locally-generated site at `http://localhost:8000/`.

