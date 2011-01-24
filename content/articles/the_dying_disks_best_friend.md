If you’ve ever had a hard drive die, whether slowly or spontaneously, you know
the horror of thinking about how you’re actually going to restore all those
backups – you _DO_ take backups, right? I don’t for a lot of my personal stuff,
knowing full well that I might end up in the same situation that a friend called
me about today. His hard drive started making the patented _Click of Death_ sound,
the obvious symptom of a near-dead hard drive.

We managed to save the majority of his files by plugging the disk into my linux
box, but not mounting it as a filesystem. Instead, using the handy unix tool `dd`
to copy the raw contents of the disk to a file:

    dd if=/dev/sdd of=/home/dave/deadhd.bin conv=noerror,sync

This command reads the contents of the device /dev/sdd and outputs it to
/home/dave/deadhd.bin. The conv options specify that dd should ignore read
errors (which are likely to occur while reading a dying disk), and to
synchronize the read position with the write position when those errors
occur. The file deadhd.bin could now be mounted:

    mount -o loop -t ntfs /home/dave/deadhd.bin /mnt/deadhd

`/mnt/deadhd` is now ready to be explored. There are bound to be files which
can’t be read, but hopefully many can be copied out and recovered. See, we don’t
need backups anyway! (_/sarcasm_)
