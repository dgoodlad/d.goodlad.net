After the big switch last year, I have been thinking hard about how to improve
my X11 environment. I’d installed [XMonad](http://www.xmonad.org/) as planned,
but there were a few snags. I continued to run the whole gnome session in the
background, replacing metacity with xmonad as the window manager. For some
reason this contributed to huge delays in startup (some unknown script was
getting hung up), in addition to various battles for control between the
two. I’ve finally taken the plunge and installed the latest beta of Ubuntu Hardy
Heron, and along with it, dropped most of gnome.

All of my system monitoring happens via small scripts piped to
[dzen](http://gotmor.googlepages.com/dzen/). This includes battery status, a
clock/calendar, volume control, mailbox monitoring, etc. The only bits of gnome
that are still running when I login are NetworkManager and its nm-applet
interface, to facilitate easy network jumping, and gnome-keyring-daemon to save
the passwords for wireless networks. Otherwise, it all might as well be
uninstalled. The benefits can be measured directly in memory usage:

    dave@eniac:~$ free -m
                 total       used       free     shared    buffers     cached
    Mem:          1994        974       1019          0         49        661
    -/+ buffers/cache:        263       1730
    Swap:         5836          0       5836

This is with firefox open, my whole dev environment (gvim plus a bunch of
terminals), mutt, etc etc. 263 MB used! Eat your heart out you big fat gnome! :)
(for comparison purposes, iirc the memory usage on a fairly clean boot into a
full gnome session was ~500 MB, but don’t take my word on that)

If anyone’s interested, I can post my xmonad config files and dzen scripts; let
me know in the comments if you’d find them useful…
