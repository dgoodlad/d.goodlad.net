## Installation Overview (tl;dr)

This describes an Arch Linux install, not Ubuntu, and doesn't use the typical
BIOS compatibility mode suggested in most linux-on-Macbook guides. As such, you
shouldn't expect a point-and-click install.

This document is a work-in-progress, but will get you around the few small issues
that are specific to this laptop.

1. Preparation
    1. Download the most recent `archboot` ISO
    2. Write the ISO to a USB stick using `dd`
    3. Prepare hard drive in OSX: (_shrink your OSX partition in Disk Utility_)
2. Partitioning and Installation
    1. Boot the USB stick (_hold `option` key to select boot drive_)
    2. Partition hard drive using `cgdisk` (GPT partitions, _not_ MBR)
    3. Install Arch to the partitions you just setup
    4. Install grub2 as bootloader, manually copying to the EFI system partition
    5. Reboot into the new system; display will be incorrect resolution - don't fret!
3. Install a new kernel
    1. Download and configure `linux-3.1.1` source, and apply i915 resolution patch
    2. Compile and install new kernel
4. Post-install: Xorg, etc.

## Preparation

Before installing anything, you'll need to prepare a USB stick, and shrink
your OSX partition using the native Disk Utility.app.

Note that there's no need to use Boot Camp to create a MBR partition table,
since we're going to boot using pure EFI mode which uses the GPT partition
table which is already present.

### Download the most recent `archboot` ISO

As of this writing, the most recent `archboot` release is `2011.10-1`. If you're
reading this from the future, grab the most recent version and send me some
cool tech from your timeframe.

As stated on the Arch Linux page, you should use one of the
[many download mirrors](http://www.archlinux.org/download/); the `archboot` iso
should be found in, low-and-behold, the `/iso/archboot` directory of your closest
mirror.

### Write the ISO to a USB stick using `dd`

Insert your USB stick. You'll need to unmount it without 'ejecting', since
that also disconnects the USB device.

    # Find your USB stick; remember the device path, something like /dev/disk2
    $ diskutil list
    # ... and unmount it
    $ diskutil unmountDisk /dev/disk2

    # Note the use of the "raw" disk device, /dev/rdisk
    $ dd if=/path/to/archlinux-2011.10-1-archboot.iso of=/dev/rdisk2 bs=8192

### Prepare hard drive in OSX

Open Disk Utility.app (in `/Applications/Utilities`). Use it to shrink your
existing OSX partition, leaving enough room for your planned Linux install. I
chose to leave 64 GB of my 256 GB drive, but it's entirely up to you.

## Partitioning and Installation

This section of the install doesn't deviate greatly from the usual Arch Linux
install process. The primary differences are the need for manual partition
creation, and manual installation of the GRUB2 bootloader to the EFI system
partition.

### Boot from the USB stick

This is the easy part: just hold down the `option` key before the apple logo
appears on the gray firmware boot screen. Using arrow keys (or the mouse),
choose the USB stick which will be mis-labeled "Windows".

GRUB will start up; choose the normal kernel.

### Partition hard drive using `cgdisk`

Before doing anything in the Arch setup script, you'll need to create one or
more partitions manually using `cgdisk`[1](#footnote-1). `cgdisk` manages a
GPT parititon table, rather than the traditional MBR-style partitions.

I created one small 100MB partition for `/boot`, leaving the remainder of the
free space for my root `/` partition. I didn't make a swap partition, but
that's up to you. I've yet to use more than 1GB of ram in my usage so far!

### Install Arch

Proceed through the normal Arch setup menus and dialogs as you would on any
other machine. Once you reach the partitioning section, though, be careful!
Don't let Arch do any partitioning of its own; instead, just move on and
choose the partitions that you've already created and tell the script where to
mount them.

### Install GRUB2 to EFI System Partition

When you get to the bootloader question, make sure to choose `grub2`. The
script will fail to fully install it, complaining about the EFI system
partition.

Swap over to a shell, and install it manually:

    # mount -t vfat /dev/sda1 /boot/efi
    # cd /boot/efi/EFI
    # mkdir boot
    # cp grub/grub.efi boot/bootx64.efi

Note that the `EFI/boot/bootx64.efi` path is very important. The OSX EFI
firmware is hardcoded to look for alternative EFI bootloaders there on 64-bit
machines.

### Reboot into the new system

Once you've finished up the Arch setup script and GRUB bootloader
installation, you should reboot into the new system. Hold `option` again to
get the list of boot options, and choose "EFI Boot". You should get the
familiar GRUB menu; choose the fallback kernel option, since the current
(as-of-this-writing) Arch-distributed kernel has issues with the keyboard when
not in HID mode.

You'll get a bit of garbage on the right and bottom edges of your screen. The
`i915` driver fails to detect the native resolution of the internal LCD panel
properly, but it's still usable.

## Install a newer kernel

To fix the keyboard issues, you'll need at least version 3.1.1 of the Linux
kernel. This version includes a number of fixes for the MacbookAir4,x series,
including the keyboard driver.

To fix the display issues, you'll need to patch the `i915` driver. The patch
includes a hardcoded set of timings, overriding what the driver (improperly)
detects.

Follow the process on the Arch Wiki page
[Kernel Compilation without ABS](https://wiki.archlinux.org/index.php/Kernel_Compilation_without_ABS),
with the following small changes:

### Patch the i915 driver

You'll need to patch the `i915` driver with the display timings appropriate
for your machine. There are, at this time, five known panels in the Macbook
Air 4,1 and 4,2 models. There is an Ubuntu-specific script that contains all
of the modelines, but requires `apt` to install the `get-edid` utility which
will identify your display.

If you don't already know which panel your machine has, you have two choices.
Either install `get-edid` yourself, and follow along with the `fix-i915.sh`
script by hand, or run the following in OSX:

```
ioreg -lw0 | grep IODisplayEDID | sed "/[^<]*</s///" | xxd -p -r | strings -6
```

Once you know which panel model you have, download the `fix-i915.sh` script
from [http://www.almostsure.com/mba42/fix-i915.sh](http://www.almostsure.com/mba42/fix-i915.sh),
and apply the patch within with the appropriate modeline for your panel.

_NOTE_ If enough people have trouble with this, I may wrap it up in an Arch-
specific script.

### Configure and compile

Follow the directions on the above-linked Arch Wiki page to configure and
compile your custom kernel.

### Add a bootloader entry for your kernel

There are two `grub.cfg` files, which can be confusing. One is in `/boot`;
this is the _wrong_ one, and unused during EFI boot. The other is on your EFI
system partition, in `EFI/grub/grub.cfg`.

Add an entry to the EFI `grub.cfg` for your new kernel, but to be safe leave
the Arch-native kernel in there too.

### REBOOT!

## Post-Install

The post-installation process is the same as for any other Arch system. You'll
likely want to install Xorg (the intel graphics driver works flawlessly), and
`pm-utils` + `acpid` for suspend support.

