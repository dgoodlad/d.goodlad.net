Up until the past few days, I have done relatively little work with
Javascript. I hacked up a small XMLHttpRequest script just before prototype.js
was added to Rails and the ‘AJAX’ term was coined, but since then I haven’t
really touched it.

For my ‘secret side-project’, I’ve been delving deeply into the world of
Javascript-powered interfaces. Now that I’ve had some time to play and learn
about the scripts and techniques that are out there, I’ve come to what I believe
to be the ultimate combination.

My pages have no javascript embedded in the HTML whatsoever, except for the
include tags in the head section. I employ a
[modified version](http://www.firelord.net/modifiedbehavior) of
[behaviour.js](http://bennolan.com/behaviour/) that uses the more powerful
[cssQuery()](http://dean.edwards.name/weblog/2005/08/cssquery2/) instead of
getElementsBySelector(). This script allows you to reverse the typical setup of
a JS-enabled page. The traditional way is to have myriad event handlers in your
HTML code, such as:

    <a href="#" onclick="call_my_function();">

If we are sticking to [web standards](http://www.webstandards.org/), we
shouldn’t be describing functionality in the HTML, just data. Besides, it just
looks ugly. Using ‘Behaviors’ I can now leave the js out of the HTML completely,
and essentially have it attach itself to event handlers, like so:

HTML:

    <ul class="actions">
      <li><a href="/foo/edit/1" class="edit">Edit</a></li>
      <li><a href="/foo/destroy/1" class="destroy">Destroy</a></li>
    </ul>

JS:

    Behavior.register(".actions .edit", function(el) {
       el.onclick = function() {
          alert("You clicked on edit!");
          // Do some AJAX goodness here
          return false;
       }
    });

So, we have the benefit of clean markup, but easily-understood Javascripts too.

The problem that I ran into, though, was that I was duplicating many of my
behavior definitions between pages. Right now I’m using mostly scaffolded
controllers and views, with your typical list/new/edit/destroy actions. The list
views are all fairly similar; we’ve got a list of items and actions that can be
performed on them. Each controller ended up with a very similar set of behaviors
defined for the list, with minor differences to account for the different types
and quantities of data being presented.

The solution, of course, was to factor out the common code. Thanks to the nice
helpers in Prototype, I was able to come up with some nice clean syntax for what
I termed ‘Standard Behaviors’. For example, if I want a destroy action link to
work via AJAX, I just call the following in an included JS script:

    new StandardBehavior.DestroyItem('recipes');

To define these standard behaviors, I use the following:

    StandardBehavior = function() {};
    StandardBehavior.prototype = {
       initialize : function(container_id) {
          this.container_id = container_id;
          this.opt = arguments[1] || {};

          this.register();
       },

       register : function() {
          Behavior.register(this.css_selector(),
                            this.get_behavior(),
                            $(this.container_id));
       },

       css_selector : function() {
          return "#" + this.container_id + " ." + this.action_name;
       }
    }

    StandardBehavior.DestroyItem = Class.create();
    StandardBehavior.DestroyItem.prototype = Object.extend(new StandardBehavior(), {
       action_name : 'destroy',

       get_behavior : function() {
          return function(el) {
             el.onclick = function() {
                //do ajax here

                return false;
             }
          }
       }
    });

If anyone is interested, I may go more in-depth about the standard behaviors in
a later post.

So, I’ve got clean, well-factored Javascript. The AJAX goodness is flowing. What
about clients who don’t have JS enabled?

I just shrug my shoulders and say that “it just works” for them too! Since none
of the JS is there, links to actions are followed just like any other
links. Instead of linking to href="#", all the links and forms actually have
real destinations. When doing an AJAX call, I use the href attribute of the link
as the target url, but return false so the browser won’t actually follow the
real link. Without the Javascript, everything works as normal, but with complete
page refreshes. Clicking on a ‘destroy’ link will go to the destroy url, and end
up redirecting to the list page. The interface doesn’t work as well as the JS
version, since it becomes clunky having to refresh the page, but it
works. Everything degrades cleanly.

You can look at this system as one designed initially for non-AJAX. Then, the
Javascripts come in and hook onto the links, maybe adding or removing some key
things to the DOM, maybe hiding some unnecessary titles, and makes things
better. Without the JS, it works as it was originally designed. To my mind, this
is beauty.
