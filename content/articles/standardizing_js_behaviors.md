I first touched on this subject in my last article, Beautiful Javascript-Powered
Pages, so I suggest reading that first if you’d like to know the background.

In my applications, I tend to have some very similar behavior requirements
across multiple pages. For example, creating a new instance of a domain object
is a relatively common behavior, and should behave similarly throughout an
application despite working with different types of records/objects. All of the
typical CRUD-type actions tend to fit this description, but it’s definitely not
limited to these actions.

As good programmers, we know what to do with ‘common’ bits of code: factor them
out! “Standard Behaviors” are the definitions of the common behaviors described
earlier, extracted to be usable everywhere with simple one-line calls.

## Supporting JS Libraries

In my implementation, I use the following wonderful Javascript libraries:

* [prototype.js](http://www.prototypejs.org/)
* [cssQuery](http://dean.edwards.name/weblog/2005/08/cssquery2/)
* [behavior.js](http://www.firelord.net/modifiedbehavior) (uses cssQuery, unlike the “original” [behaviour.js](http://bennolan.com/behaviour/))

This is my personal arsenal of libraries; if you prefer other ones, feel free to
adapt these ideas to your needs.

## Defining a Standard Behavior

As described in my [previous article<sup>1</sup>](#fn1), here is the basic definition of the base
StandardBehavior class:

    StandardBehavior = function() {};
    StandardBehavior.prototype = {
       initialize : function(css_selector, container) {
          this.css_selector = css_selector;
          this.container = container
          this.opt = arguments[2] || {};

          this.register();
       },

       register : function() {
          Behavior.register(this.css_selector,
                            this.get_behavior(),
                            $(this.container));
       }
    }

## Usage

The usage of standard behaviors is quite straightforward. To define your own
standard behavior, simply subclass StandardBehavior, and define the
get_behavior() method, like so:

    StandardBehavior.MyBehavior = Class.create();
    StandardBehavior.MyBehavior.prototype =
      Object.extend(new StandardBehavior(), {
       get_behavior : function() {
          return function(el) {
             el.onclick = function() {
                alert('Hello from standard behavior!');
                return false;
             }
          }
       }
    });

Notice that the anonymous function returned by get_behavior() is of the form
you’d use when calling Behavior.register()? This function gets passed directly
to Behavior.register(), so you can basically just extract your current behaviors
into this with minimal effort.

Once you’ve defined a standard behavior class, you can actually bind it to
specific DOM elements by using something like the following:

    new StandardBehavior.MyBehavior(".actions a.bar", 'content');

This would cause any links of class ‘bar’ with a parent that has class
‘actions’, contained within a DOM element with id ‘content’ (whew!) to issue an
alert whenever they’re clicked.

Simple beauty, if I must say so myself!

## Sample Standard Behaviors

Enough talk of generalities and theories; let’s see some examples of real-life
code! I’ll stick to two of the main actions that one might do with a ‘list’
view: edit an item, and destroy an item. In this case, to keep things
interesting, we’ll pretend that we’re viewing a list of ‘products’.

### HTML

The following is a sample of the HTML that would be the target for these
standard behaviors:

    <ul id="products">
      <li id="product1">
        <ul class="actions">
          <li class="edit"><a href="/products/edit/1">Change me!</a></li>
          <li class="destroy"><a href="/products/destroy/1">Delete</a></li>
        </ul>
        <div class="product">
          <h3>Widget</h3>
          $3.00 each
        </div>
      </li>
      <li id="product2">
        <ul class="actions">
          <li class="edit"><a href="/products/edit/2">Change me!</a></li>
          <li class="destroy"><a href="/products/destroy/2">Delete</a></li>
        </ul>
        <div class="product">
          <h3>Gadget</h3>
          $10.00 / pair
        </div>
      </li>
    </ul>

Each entry in the list has a set of actions associated with it, and a div
containing the actual product information.

note: As Bob Aman pointed out in a comment on my last article, one should always
be careful when implementing destructive operations as links – Google Web
Accelerator will happily follow them, causing all sorts of havoc. I describe the
use of links for all the CRUD actions here, but when developing anything for the
web you should take whatever measures you feel necessary for your
application/site to ensure that GWA doesn’t hurt you!

### One Helper Function

Just for cleanliness, let’s setup a helper function that will give us the
containing ‘li’ element of an action link:

    container_for_action = function(action) {
       return action.parentNode.parentNode.parentNode;
    }

### Edit

Let’s get started with the simple ‘edit’ action. First, we define a standard
behavior subclass called EditItem. We’ll say that when an edit link is clicked,
we’ll use AJAX to update the contents of the div element containing the related
product.

    StandardBehavior.EditItem = Class.create();
    StandardBehavior.EditItem.prototype =
      Object.extend(new StandardBehavior(), {
       get_behavior : function() {
          item_class = this.opt.item_class;

          return function(el) {
             container = container_for_action(this);
             item = cssQuery('.' + item_class, container)[0];

             new Ajax.Updater({success: item, failure: 'ajax_error'},
               this.href,
               { asynchronous: true,
                 onComplete: function(request) {
                   Behavior.apply();
                 }
               }
             );
          }
       }
    });

To bind this behavior to our example HTML, we’d include a line like this:

    new StandardBehavior.EditItem('.actions a.edit',
      'products',
      {item_class: 'product'}
    );

One small thing to note is the use of the optional third parameter in the
constructor; you’ll find this familiar from Prototype and script.aculo.us. We
can pass arbitrary options here as key/value pairs. In this case, EditItem needs
to know the DOM class that we’ll be using to identify item divs in our list.

Edit is a very straightforward behavior to implement; here, it is a basic ajax
updater that replaces the contents of the product’s div with the response from
/products/edit/1, which presumably would be a form with a submit button and
cancel link.

Much more can be done with a behavior like this. Things such as fading out the
other items in the list, hiding actions that are inappropriate at this time, and
others could easily be dropped in. However, this article would get far too large
if every possible user interface extension was explored, so these will be left
as an exercise for you, the reader!

### Destroy

The destroy behavior is very similar to that for edit, so we’ll breeze over it quickly:

    StandardBehavior.DestroyItem = Class.create();
    StandardBehavior.DestroyItem.prototype =
      Object.extend(new StandardBehavior(), {
       get_behavior : function() {
          return function(el) {
             el.onclick = function() {
                container = container_for_action(this);

                new Ajax.Request(this.href,
                  { onSuccess : function(request) {
                      new Effect.BlindUp(container, {
                        afterFinish: function(effect) {
                          Element.remove(container);
                        }
                      });
                    }
                  }
                );

                return false;
             }
          }
       }
    });

Here, we use a simple BlindUp effect from the
[script.aculo.us effects library](http://script.aculo.us/) to animate the
removal of an item, then remove it from the DOM once the effect is complete.

In the case of this behavior, we don’t have any special options like we did with
edit, so the basic binding would be accomplished by:

    new StandardBehavior.DestroyItem('.actions a.destroy', 'products');

That wasn’t too exciting, was it? Moving right along!

### Submitting Edit Forms

What you may have noticed is that we may be able to ‘initiate’ the editing of an
item now, but when we actually submit the form, we’re back to plain ol’
whole-page-refreshes. Let’s fix that with yet another standard behavior:

    StandardBehavior.SubmitEditForm = Class.create();
    StandardBehavior.SubmitEditForm.prototype =
      Object.extend(new StandardBehavior(), {
       get_behavior : function() {
          return function(form) {
             form.onsubmit = function() {
                item = this.parentNode;
                container = item.parentNode;

                new Ajax.Updater({success: item, failure: 'ajax_error'},
                  form.action,
                  {    asynchronous:true, parameters:Form.serialize(form) }
                );

                return false;
             }
          }
       }
    });

This behavior will not actually get bound to anything when you instantiate it,
but the call to Behavior.apply() in the original EditItem behavior will after
the form is created. You create an instance of this behavior just like all the
others:

    new StandardBehavior.DestroyItem('.product form', 'products');

### Examples Summary

There are innumerable other standard behaviors that one could come up with; even
for a simple CRUD list view we could keep going for a Very Long
Time&tm;. However, the basic edit/destroy behaviors should serve as a great
example of how they work.

You’ll notice how the binding calls to these behaviors are what specify what
kinds of items we’re dealing with, and how to find them using CSS selectors. The
behaviors themselves don’t need to know too much about what data they’re dealing
with, nor do they need to know a lot about your DOM structure. Because of this
decoupling, you can now use these standard behaviors anywhere you have a list of
items that follows the same type of structure as used for the products
list. Further generalizations could be made, but that’s up to your needs!

The other important thing to notice is that we’re always using the href property
of links (or the action property of forms) to determine the url for our ajax
requests. These links and buttons will work just as well without javascript
enabled as they will with; just make sure your backend is designed appropriately
to handle the two types of requests, spitting out header-/footer- free HTML when
an ajax request comes in!

## Benefits of Standard Behaviors

### Graceful Degredation for free

As mentioned in the summary of the example section, this method of using
javascript behaviors degrades gracefully for the cases when javascript is
unavailable in a client browser. This benefit is gained ‘for free’, so long as
you’re careful about your design.

### Clean HTML

Not a shred of Javascript is to be seen in your HTML, besides the script tags in
your header. Your document structure is pristine, and uncluttered by ugly
onclick="foo();" attributes.

### Consistency throughout your application

One of the largest benefits for both you as a developer and for your users is
that your application/website will be consistent in its behavior. By factoring
out standard functionality, you can ensure that specific actions will be
displayed to the user in the same way in every place. For example, you probably
want to give subtle visual cues to the user about the results of their actions
(a la the classic “Yellow Fade Technique”). Using standard behaviors, you will
know that every time “something” is edited in your application, whether that
“something” be a product, a comment, or a user, the user will be given the same
visual cues.

Standard behaviors are really a simple application of the DRY principle. As
such, they help both you as the developer by making your mounds of code more
maintainable (and readable to boot!).

## Conclusions

Hopefully some of you get some use out of this far more in-depth article. I find
these techniques have not only saved me a ton of headaches, but they’ve saved my
test users frustration as well!

Please feel free to leave feedback via the comment system here; I welcome any
constructive criticism, of course! I can also be contacted via e-mail at
d[nospam]goodlad@gmail.com.

## Footnotes

<p id="fn1">1: I have modified the base StandardBehavior class from the original version to make it fit the general case a little better</p>
