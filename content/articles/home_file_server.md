## Hardware

The parts for this server were researched and purchased in December 2010. My
reasoning for the different parts varies, but follows two simple design goals:

1. _Storage First_: maximize storage capacity
2. _Silence is Golden_: a computer in a home living space shouldn't be noisy

The final parts list ended up like this:

 Part | Model | Price
------|-------|-------
Case | Fractal Design [Define R3](http://www.fractal-design.com/?view=product&category=2&prod=48) | $145
Motherboard | Gigabyte [GA-890GPA-UD3H](http://www.gigabyte.com/products/product-page.aspx?pid=3516#ov) | $160
Power Supply | Antec TruePower 750W | $144
CPU | AMD Phenom II X2 555 (3.2GHz dual-core) | $94
RAM | 4 GB Kingston ValueRAM (2x2GB) 1333MHz DDR3 | $90
SAS Controllers | 2x DELL SAS 5 PCIe - see [this forum post](http://forums.overclockers.com.au/showthread.php?t=879827) | $30
HDDs | 8x 1TB Seagate 7200rpm | $544

_note_: I sourced all of these parts, except for the SAS controllers, at a local
parts store in Melbourne, Australia in December 2010. The prices listed are in
AUD, and are what I paid at that time.

The case was the most difficult piece of the puzzle to find, but was absolutely
key in making the rest of the build possible. The _Define R3_ has excellent
noise properties thanks to sound-deadening insulation on the side and top panels
and silicon-grommeted hard drive mounts. It also sports eight 3.5" drive bays,
individually accessible from the side. They aren't quite as nice as
hot-swappable bays, but this is not a high-availability server -- I can afford
to bring the machine down for a short time to swap out a disk.

The motherboard was chosen mainly for its two PCIe x16 slots, to support the two
SAS controllers. The CPU and RAM were simply the reasonably-priced choices
available at the time.

![Server](/assets/images/articles/home_file_server/server.jpg)

### Notes about the SAS controllers

The SAS controllers are a bit tricky. For 10 USD each, they are an incredible
bargain for a card based on the well-known LSI 1068 chipset. However, they use
the now-uncommon SFF-8484 connector to attach to your drives (or to a backplane
if that's what you've got).

Finding SFF-8484 to 4x SATA fanout cables on ebay is _easy_; identifying the
orientation of these cables before you buy is _hard_. In fact, finding any
straightforward information about these cables is difficult unless you're
involved in enterprise hardware. I finally found a
[guide to identify HOST and TARGET SFF-8484 fanout cables](http://reviews.ebay.com.au/How-to-Identify-HOST-and-TARGET-SFF-8484-Fanout-Cables_W0QQugidZ10000000016502645)
which was very useful.

In case the guide ever disappears, the key take-away is that to connect a SAS
controller to four SATA HDDs, you need a HOST SFF-8484 cable. To identify such a
cable, lay it out flat and locate the notches (or 'keys') on both the SFF-8484
and SATA connectors. If they are on the _same_ side of the cable, you have a
HOST cable.


## Software Installation

FreeNAS is designed to be installed on small flash-based media, _eg_: Compact
Flash card or USB stick. I happened to have an old 8GB USB stick lying around,
but could just as easily have gone and picked one up for less than $20.

### Imaging the USB stick

Instead of downloading and burning an ISO cd image, then using it to install
onto the flash drive, it's much easier to download an image of a pre-installed
system that can be copied directly onto the flash drive. FreeNAS distributes
three different files for each release; if you're following along, you'll want
the one named like `FreeNAS-8.0.1-BETA2-amd64-Full_Install.xz` (note the
'Full_Install' bit).

I used [Keka.app](http://www.kekaosx.com/) to decompress the image on my
OSX-based machine. On many modern linux distributions, you can probably use the
native `xz` utility instead. I then inserted my USB key and imaged it with the
decompressed file:

    $ diskutil list
    /dev/disk0
       #:                       TYPE NAME             SIZE       IDENTIFIER
       0:      GUID_partition_scheme                 *121.3 GB   disk0
       1:                        EFI                  209.7 MB   disk0s1
       2:          Apple_CoreStorage                  120.5 GB   disk0s2
       3:                 Apple_Boot Recovery HD      650.0 MB   disk0s3
    /dev/disk1
       #:                       TYPE NAME             SIZE       IDENTIFIER
       0:                  Apple_HFS Macintosh HD    *120.2 GB   disk1
    /dev/disk2
       #:                       TYPE NAME             SIZE       IDENTIFIER
       0:      GUID_partition_scheme                 *4.1 GB     disk2
       1:                        EFI                  209.7 MB   disk2s1
       2:       Microsoft Basic Data KINGSTON         3.9 GB     disk2s2

The first two disks are my Macbook Air's internal SSD; `/dev/disk2` is my
Kingston USB drive.

    $ diskutil unmountDisk /dev/disk2
    Unmount of all volumes on disk2 was successful

    $ dd if=Downloads/FreeNAS-8.0.1-BETA2-amd64-Full_Install of=/dev/disk2 bs=5k
    195312+1 records in
    195312+1 records out
    1000000000 bytes transferred in 2061.441201 secs (485098 bytes/sec)

This may take a while if your drive is very slow like mine. `dd` will not output
anything at all until it's done, so don't panic! The `bs=5k` block size
parameter is copied from the FreeNAS documentation; it may be okay to increase
that value to speed up the process, but I was unsure of the impact so didn't
mess with it.

### First boot, and configuration

I booted up the server with the freshly-imaged USB stick inserted in one of the
rear USB ports, and once I'd configured the BIOS to boot from USB first it
jumped straight into the FreeBSD bootloader.

Once the system had finished booting, a small menu of options was presented on
the console. Since the default network configuration (DHCP) was fine for my LAN,
I didn't need to do anything here. At the bottom of the screen, the machine's IP
address was listed - enough for me to grab my laptop and load up the FreeNAS web
interface.

### Storage setup

I decided to configure a single ZFS pool (_zpool_) striped across a pair of
4-drive RAID-Z1 arrays (_vdevs_). This gives me the flexibility to upgrade 4
drives at a time, and remains faster than a single RAID-Z or traditional RAID-5
array.

There are rumors around the internet that RAID-Z arrays perform at their best
with the number of data disks being a power of two, but these were never
substantiated in the articles about larger enterprise installations. If I'd
wanted believe this theory, I could have setup a 6-drive RAID-Z2 array, or
bought another pair of drives and had 2 5-drive RAID-Z arrays. In my case, it
wasn't critical to squeeze every ounce of performance out of the system, so I
didn't worry about it.

The method to create the single _zpool_ with two _vdevs_ is not immediately
obvious. First, create a 'Volume' configured as if you were only going to use
one _vdev_. In this case, I created a Volume named `vault` using the first 4
drives, choosing 'ZFS' for the filesystem and RAID-Z for the group type. To add
a second _vdev_, you simply repeat the same volume creation process, using the
**same volume name**. I went through the create volume screen again, using
`vault` as the volume name and choosing the remaining 4 drives for ZFS RAID-Z,
and ended up with a 5.9TB volume.

The above is equivalent to the following command-line:

    $ zpool create vault raidz /dev/da0 /dev/da1 /dev/da2 /dev/da3
    $ zpool add vault raidz /dev/da4 /dev/da5 /dev/da6 /dev/da7

### Sharing files

Configuring ZFS datasets and sharing them is straightforward, but very specific
to what one needs to do with the file server. Check out the FreeNAS docs for
more info.


## Fine-tuning

I've got a few more things that I want to add to this machine.

### Time Machine backups

Version 2.1 of `netatalk`, the AFP service daemon, that comes with FreeNAS 8 is
not new enough to support hack-less Time Machine backups. You can make it work,
but it's ugly and unstable. The FreeBSD ports system doesn't have any of the
netatalk-2.2 betas available, so it looks like I'll likely have to write my own.

*UPDATE*: The most recent version of FreeNAS, 8.0.2-RELEASE, includes an updated
version of `netatalk`. It supports the features required by Lion for
out-of-the-box Time Machine support.

### SABnzbd, Sick Beard and Couch Potato

I use these tools to acquire video from usenet. I'm considering moving these
from my Mac Mini to the file server, but have yet to decide if I'll do so.

*UPDATE*: I have installed all of these, and they're running nicely. There
are a number of people on the FreeNAS forums who have done so and documented
their experiences.


