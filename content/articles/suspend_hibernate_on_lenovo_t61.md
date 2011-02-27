In Ubuntu 7.10, I had suspend working fine while using the nvidia proprietary
driver. However, this stopped working when I installed the latest beta of Ubuntu
Hardy Heron. I discovered that it was due to some invalid assumptions in the
hal-info package. After some discussion on the hal mailing list, I did some
testing of suspend/hibernate with the opensource nv driver. I determined that
the following two ‘quirks’ were required for both suspend and hibernate to
function consistently:

`quirk.s3_bios` and `quirk.vbemode_restore`

Using the nvidia proprietary driver is a different beast entirely. Most articles
will mention that `s3_mode` is required, and nothing else. In my case, both
s3_mode and save_pci were necessary to avoid catastrophe upon resume. I still
can’t get hibernate to work with this driver, but suspend is fine for me.

You can set these quirks in two places; the existing article on the Ubuntu wiki
for the T61 says to modify `/etc/default/acpi-support`, which is only valid for
Gutsy. `gnome-power-manager` in Hardy seems to use the data from the `hal-info`
package instead, now, which is contained in a bunch of xml files in
`/usr/share/hal/fdi/information/10freedesktop/20-video-quirk-pm*`. In my case, I
edited the `20-video-quirk-pm-lenovo.fdi` file, adding an entry specifically tuned
for my _646066U_ model:

    <!-- T61 646066U uses NVidia driver -->
    <match key="system.hardware.product" string="646066U">
      <!-- Proprietray NVidia driver quirks -->
      <merge key="power_management.quirk.s3_mode" type="bool">true</merge>
      <merge key="power_management.quirk.s3_bios" type="bool">false</merge>
      <merge key="power_management.quirk.save_pci" type="bool">true</merge>

      <!-- Opensource nv driver -->
      <!--<merge key="power_management.quirk.s3_bios" type="bool">true</merge>
      <merge key="power_management.quirk.vbemode_restore" type="bool">true</merge>-->
    </match>

I’ve included quirks for both drivers, you’ll have to pick which one you’re using.

On a related note, since I don’t use gnome any more, `gnome-power-manager` is no
longer loaded when I login. I had to edit `/etc/acpi/sleepbtn.sh` to force it to
run the `sleep.sh` script instead of just sending a fake keypress to X:

    #!/bin/bash
    . /usr/share/acpi-support/key-constants
    #acpi_fakekey $KEY_SLEEP
    /etc/acpi/sleep.sh

Per [Debian bug #467374](http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=467374) this
shouldn’t be necessary for long, though.
