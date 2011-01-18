## What is Babushka?

[Babushka](http://babushka.me/) is, as [@ben_h](http://twitter.com/ben_h)
describes it, a tool for "test-driven sysadmin":

> The idea is this: you take a job that you'd rather not do manually, and
> describe it to babushka using its DSL. The way it works, babushka not only
> knows how to accomplish each part of the job, it also knows how to check if
> each part is already done. You're teaching babushka to achieve an end goal
> with whatever runtime conditions you throw at it, not just to perform the task
> that would get you there from the very start.

Using a straightforward Ruby DSL, you describe how to detect the completion
state of a given 'dep', and how to meet that dep.

    dep 'ip forwarding enabled' do
      met? {
	File.read('/proc/sys/net/ipv4/ip_forward') == '1'
      }
      meet {
	`echo 1 > /proc/sys/net/ipv4/ip_forward`
      }
    end

## Why Use Babushka on Workstations?

When you set up a new computer, whether it's your primary workstation or a
lightly-used travel laptop, it's useful to keep a record of what you've done:
"install version _X_ of application _Y_", "configure _obscure setting_", and so
on. Later on, you can use such a record to help you remember what you've done,
to help others, or to completely rebuild your system from scratch with minimal
effort.

I've recently gone through that last one: I bought a new laptop and decided I
wanted to start fresh. Since I'd been using Babushka to install and configure
the majority of my software, building the new machine took very little effort. I
updated a few download links to point at the latest versions, pruned a bunch of
apps that I'd never use again, then ran `babushka orion` (_orion_ is the name of
my laptop, and of the dep that is configured to require everything that I want
on it).

... _20 minutes later_ ...

Aside from a few small changes that I'd planned to make as soon as I had the
chance to start fresh, my laptop was all setup and ready to go!

## Getting Started

Now that you're convinced that this could be a good idea, you should probably give it a try!

I'll assume that you're running on a platform with built-in managed package support in Babushka:

* OSX 10.5+ (uses [Homebrew](http://github.com/mxcl/homebrew))
* Debian, Ubuntu, or other apt-based Linux distributions

### Installing Babushka

The easiest way to get Babushka up and running is to follow the
[instructions](http://babushka.me/#get_it):

    bash -c "`curl babushka.me/up`"      # OSX has curl
    # or...
    bash -c "`wget -O - babushka.me/up`" # Most linux distros have wget

### Meeting Deps

Once Babushka is installed, you can use it to _meet_ deps. The meaning of _meet_
depends on how the dep is defined. A dep which installs software would probably
be considered _met_ if an appropriate binary can be found in your `$PATH`. A dep
that configures an entry in the `/etc/hosts` file would, obviously, be
considered _met_ if there was a matching line in that file.

To meet a dep, you simply run

    babushka [source]:[depname]

Your own deps are in a source called _personal_. The _personal_ source is the
default, so to meet a dep that you've written yourself you can run

    babushka [depname]

### Writing Your Deps

Babushka installs a number of base deps that it uses to configure itself, but
your own deps should go in `~/.babushka/deps/`. If this directory doesn't exist,
you should create it. I use `git` to track the changes that I make to my
personal deps, which I highly recommend doing. Simply run `git init` in your
`deps` directory and you'll be ready to go.

You're free to write deps from scratch, but for many common cases there are
'templates' that come with Babushka. Some useful built-in templates are

* _managed_: Installs software via the system's package manager. As described
  above, Homebrew on OSX, apt on Linux
* _app_: Installs OSX app bundles
* _installer_: Installs OSX `.pkg`/`.mkpg` installer files
* _src_: Installs software from source, by default using the typical
  `configure`, `make`, `make install` steps.

There are others, and it's easy to write your own (see my
[ttf template](https://github.com/dgoodlad/babushka-deps/blob/master/osx.rb#L20)
for example).

Let's write a dep that installs the `tree` package from your system's package
manager. Put the following into a file with the extension `.rb` (maybe
`packages.rb` or `system.rb`?) in your deps directory:

    dep 'tree.managed'

Now if you run `babushka list`, you'll see something like:

    $ babushka list | grep tree
    babushka 'personal:tree.managed'

Since the _personal_ source is the default, we can meet the dep like so:

    $ babushka tree.managed

    √ Loaded 38 deps from /usr/local/babushka/deps.
    √ Loaded 123 and skipped 1 deps from /Users/dave/.babushka/deps.
    tree.managed {
      homebrew {
	homebrew binary in place {
	  homebrew installed {
	  } √ homebrew installed
	} √ homebrew binary in place
	build tools {
	  llvm in path {
	    xcode tools {
	    } √ xcode tools
	  } √ llvm in path
	} √ build tools
      } √ homebrew
      'tree' is missing.
      not already met.
      Homebrew package lists are 7 days old. Updating... done.
      Installing tree via brew {
	==> Downloading ftp://mama.indstate.edu/linux/tree/tree-1.5.3.tgz
	File already downloaded and cached to /Users/dave/Library/Caches/Homebrew
	==> /usr/bin/cc -O3 -w -pipe -o tree tree.c strverscmp.c
	/usr/local/Cellar/tree/1.5.3: 4 files, 88K, built in 2 seconds
      }
      'tree' runs from /usr/local/bin.
      tree.managed met.
    } √ tree.managed

## Collecting Deps

I have a file in my deps repository called `orion.rb`. _Orion_ is the hostname
of my Macbook Pro laptop. In this file, I have a couple of high-level deps that
don't actually have met/meet blocks. Instead, they simply require other deps. It
looks something like this:

    # Complete setup for my Macbook Pro, 'orion'

    dep 'orion' do
      requires 'orion osx apps installed'

      requires 'macvim',
	       'tmux',
	       'ack.managed',
	       'tree.managed'

      requires 'rvm'
      requires 'nvm'
    end

    dep 'orion osx apps installed' do
      # Social, Web, Media etc.
      requires 'Google Chrome.app',
	       'Echofon.app',
	       'Skype.app',
	       'LimeChat.app',
	       'Airfoil.app'
      # ... and lots more
    end

Whenever I write a dep that I want to ensure will be met on my laptop, I
add it to the list of requirements for these high-level deps. Then, instead of
telling Babushka to meet low-level deps directly, I meet my top-level
`orion` dep. This ensures that the high-level dep is an accurate representation
of the system as it stands, and that I can quickly and easily rebuild the OS
should I do something like buy a new machine.

## Common Pitfalls

When writing your own deps based on the built-in Babushka templates, you'll
sometimes run into things that don't _quite_ fit the expected behavior. The most
common cases involve software that gets installed into non-standard places.

### Missing Binaries

If you're trying to install a package with the _managed_, _src_, _app_ or
_installer_ templates, they expect that installing will result in a binary being
installed in your path with the same name as the package. For example,
`htop.managed` by default is considered _met_ if there is a binary called `htop`
in your path.

To override the check for binaries, use the `provides` method:

    dep 'gnu-typist.managed' do
      # In Homebrew, GNU Typist is in a formula called gnu-typist, and installs
      # a binary named gtypist.
      provides 'gtypist'
    end

    dep 'freeimage.managed' do
      # The library freeimage doesn't provide any binaries
      # The template will still check that the package is installed, though
      provides []
    end

    dep 'erlang-nox.managed' do
      # The erlang-nox package installs two important binaries, so we should
      # verify that both are present
      provides 'erlc', 'erl'
    end

### Non-Applications

When you use the _installer_ template to install OSX pkg/mpkg files, you're not
always installing an application into /Applications. Instead, you might be
installing a prefpane, or a kernel extension. Overriding `met?` is usually the
best thing to do in these cases. For example:

    dep 'KeyRemap4MacBook.installer' do
      source 'http://pqrs.org/macosx/keyremap4macbook/files/KeyRemap4MacBook-6.9.0.pkg.zip'
      met? {
        # Test that the prefpane is in the right place.
	'/Library/PreferencePanes/KeyRemap4MacBook.prefPane'.p.exist?
      }
    end

## More Help

This article merely scratches the surface of what you can do with
Babushka. If you'd like to learn more, or run into issues, there are a few
places to turn.

* The [Babushka Google Group](http://groups.google.com/group/babushka_app) is
probably a good place to start. Searching through past posts might turn up
someone who's having the same issue, and failing that you can always ask your
own question!

* My entire set of deps is available publicly on Github:
[github.com/dgoodlad/babushka-deps](http://github.com/dgoodlad/babushka-deps/)

* Ben Hoskings, the author and active maintainer of Babushka, also has his deps
available publicly:
[github.com/benhoskings/babushka-deps](http://github.com/benhoskings/babushka-deps/)

* For more details about Babushka, see the
[readme on Github](https://github.com/benhoskings/babushka#readme) and the
[Babushka homepage](http://babushka.me)
