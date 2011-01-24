Now that Rick Olson has
[integrated](http://weblog.rubyonrails.org/2006/8/1/simply-restful-in-rails-edge)
the functionality of the simply\_restful plugin with Rails Core, the interest in
RESTful design in Rails is bound to increase. I’ve found that most of the
documentation is rather out-dated, and that it takes a bit of digging to figure
out exactly what syntax you should be using for your named routes, url
generation, etc. Differences between the simply_restful README, DHH’s
[presentation](http://www.loudthinking.com/lt-files/worldofresources.pdf) from
RailsConf, and various random blog posts, it can get rather confusing!  Let’s
clear that up, shall we?

## URL Structure

First of all, something that many of you are familiar with: the URL
structure. There are 3 basic URLs, but each can respond to the various HTTP
verbs in different ways. Using a Order model:

<table>
  <thead>
    <tr>
      <th>Named Route</th>
      <th>URL</th>
      <th>HTTP Verb</th>
      <th>Controller Action</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>orders_url</td><td>/posts</td><td>GET</td><td>index</td></tr>
    <tr><td>orders_url</td><td>/posts</td><td>POST</td><td>create</td></tr>
    <tr><td>order_url</td><td>/posts/:id</td><td>GET</td><td>show</td></tr>
    <tr><td>order_url</td><td>/posts/:id</td><td>PUT</td><td>update</td></tr>
    <tr><td>order_url</td><td>/posts/:id</td><td>DELETE</td><td>destroy</td></tr>
    <tr><td>new_order_url</td><td>/posts/new</td><td>GET</td><td>new</td></tr>
    <tr><td>edit_order_url</td><td>/posts/id;edit</td><td>GET</td><td>edit</td></tr>
  </tbody>
</table>

The plural form of the named route can be thought of as the ‘collection’ URL. It
allows operations on the collection as a whole:

1.  Get a list of all the entities, in this case orders (GET)
2.  Create a new entity (POST)

The singular form of the named route, on the other hand, is used to refer to a
specific entity in the collection: in this case, a post. By using the GET, PUT,
and DELETE verbs, you can operate on this entity:

1. Show the attributes of a specific entity (GET)
2. Update the attributes of a specific entity (PUT)
3. Destroy a specific entity (DELETE)

There are two ‘oddball’ URLs: ‘new’ and ‘edit’. They are used to show forms for
submission to the ‘create’ and ‘update’ URLs (via the appropriate verb).

## Setting up routes.rb

To map a model as a resource, an entity that can be operated upon in the manner
described above, you add a line to your config/routes.rb file:

    ActionController::Routing::Routes.draw do |map|
      map.resources :orders
    end

Multiple resources can be specified on the same line, reducing clutter:

    map.resources :orders, :invoices, :customers

Resources can also be nested, to produce URLS like /orders/1/invoices/3:

    map.resources :orders do |map|
      map.resources :invoices
    end

There are a number of optional parameters to the #resource method, but I’ll
leave these alone for now…

## Controller

There are seven standard controller actions. Following the Order model example:

    class OrdersController < ApplicationController
      def index
      end

      def show
      end

      def new
      end

      def create
      end

      def edit
      end

      def update
      end

      def destroy
      end
    end

This boilerplate code is enough to respond to all of the default URLs defined by
the map.resources call.

## Parameters

When the singular entity URL is requested, you’ll have access to the ID
requested in the params[:id] variable.

A create or update request will give you the new attributes in a hash accessed
by params[:entity\_name]. For example, params[:order].

When a nested URL is requested (described above), you’ll have access to all the
‘parent’ IDs based on the name of the model. For example, if you had invoices
nested in orders, like the example above, you would receive params[:order\_id] in
your controller. Not surprising, is it?

## Named Routes

Using the named routes is remarkably easy. Assuming the Order model, like
before, and that for the singular urls you have an instance of an order
available in the @order variable, you can link to the various controller
actions:

<table>
  <thead>
    <tr>
      <th>Controller Action</th>
      <th>Method to call</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>index</td><td><code>link_to orders_url</code></td></tr>
    <tr><td>show</td><td><code>link_to order_url(@order)</code></td></tr>
    <tr><td>new</td><td><code>link_to new_order_url</code></td></tr>
    <tr><td>create</td><td><code>form_for :order, :url => orders_url, :html => { :method => :post }</code></td></tr>
    <tr><td>edit</td><td><code>link_to edit_order_url(@order)</code></td></tr>
    <tr><td>update</td><td><code>form_for :order, :url => order_url(@order), :html => { :method => :put }</code></td></tr>
    <tr><td>destroy</td><td><code>link_to order_url(@order), :method => :delete</code></td></tr>
  </tbody>
</table>

Note that you can pass the instance you want directly to the singular
route. Also note that the :method parameter is not given to the named route,
rather it’s passed to either link\_to or form\_for (or their variants). This last
one has frustrated me before.

The named routes for nested resources operate in the same way; you just need to
pass the ‘parent’ resource(s) as the first parameter(s):

    invoices_url(@order)
    invoice_url(@order, @invoice)

## The Basics: Check!

Those are the basics needed to get started using the RESTful functionality,
correct as of the date of this post. There are many options and fancy methods of
extending this functionality, but I’ll leave those for another article. The
defaults seem to cover a huge range of possible uses, so make a good place to
start.

