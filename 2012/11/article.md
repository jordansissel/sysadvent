# DC Ops Tips

This was written by [Chris Webber](https://twitter.com/cwebber).

With all the talk and movement to the cloud, it is easy to forget that many of
us still have datacenter ops responsibilities. For many, they don't even know
it as DC Ops, but just simply as a job duty. DC Ops, or Datacenter Operations,
is, in it's simplest form, taking care of the operations that happen inside the
datacenter. This datacenter may very well be a closet for some of us, but it is
nevertheless, the datacenter.

Like the terms Operations or Systems Administration, what tasks are involved in
DC Ops vary widely. Nothing said herein is written as a rule but as something
to think about. Additionally, just like all things in our field, what has
worked for me won't necessarily work in your environment. Here are a few
things that I think are important and that I find that even people with
many years of experience don't always know.

## Equipment

For me, there is always a basic set of gear that I take with me to the DC. When
I had multi-DC responsibilities, all of these things went into a backpack that
went with me. Now that I really only have responsibilities at one location,
they sit on the table and on the shelf in the DC. 

### The Basics

* **Drill** - While most drills will do, there are a few things I look for:
 * *Small* - I love the little Makita 12V drills.
 * *Variable Speed* - There are two parts to this. A switch on top that changes
   the max and the ability to adjust based on how the trigger is pulled.
 * *Variable Torque* - This is the numbers that you can change on front of the
   drill. In general, I find that it is good to keep this number around 3-6 on
   most drills. This setting will help prevent accidental stripping of screw heads.
* **Drill Bits** - This is one of the areas where the more the better, but here
  is a list of what I would make sure you have as a minimum. Additionally,
  magnetic bits will save your ass… Just sayin.
 * *\#1, \#2 & \#3 Philips Head Bits* - Yes, you need all three. \#2 is the most
   common, but you will need the \#3 when dealing with most M6 screws and the
   \#1 when dealing with the smaller screws inside systems.
 * *Standard (Flat) Head Bit* - These come in handy for various things, not to
   mention standard screws. It is good to keep a few sizes handy.
 * *Bit Extension* - You will want an extension in your kit. I use one that is
   about 12" long but anything 3" or longer should be good enough. Look for
   ones that are magnetic.
* **Kneepads** - Yes, kneepads. These will make all the difference in the world
  if you are up and down off the floor at all. I tend to prefer the ones with
  hard caps on them because I can slide on the DC floor.
* **Mechanics Gloves** - I tend to pick up a few pairs of the Craftsman ones
  around the holidays. These will save your hands from cuts when dealing with
  rails and cardboard. Additionally, I find it much easier to do long runs of
  cables with gloves on.
* **Label Maker** - I will go into more details about which ones I use and why
  in the [Labeling](#Labeling) section.
* **Flashlight** - Something that is more than say 30 Lumens is probably your
  best bet.
* **Utility Knife** - Boxes, tape, cable, need I say more?
* **Hearing Protection** - If you are going to be in the DC for any substantial
  amount of time, earplugs or earmuffs will make a world of difference.
  Everyone I know that has been doing this for more than a decade seems to have
  hearing loss, and it's always a good idea to protect ourselves.
* **Adjustable Wrench** - Also known as a Crescent wrench, these are great for
  lowering feet on racks and other misc things.


### Always Be Prepared

Below is the list of things that are not required but, have been added to my
kit over the years.

* **Impact Driver** - Between putting holes in racks and "gently" modify rail
  kits, having an impact driver for those stubborn tasks is nice.
* **Torx/Security Bit Set** - Torx bits are also called 'star' bits. I swear
  some vendors have an obsession with making things hard. These usually solve
  that problem.
* **Titanium Drill Bit Index** - These usually get combined with the impact
  driver for what I like to refer to as, "creative problem solving."
* **Headlamp** - It is nice to have light and both your hands free.
* **Flex Driver Extension** - If you are in a legacy environment, this is a
  must. Someone always seems to put something in front of the screws that need
  unscrewing.
* **Socket Set** - I don't use it often, but when I do, it is a huge lifesaver.
* **"Horizontal" Screwdriver** - The best way to explain this is the
  screwdriver you can use to remove the ears from a switch while it the ears
  are still attached to the rack.
* **Bright Ethernet Cables** - Keeps you from forgetting them and handy in a
  pinch.
* **Inline Coupler** - These are evil when used to make 100 ft. cables, but
  invaluable when you need to keep a console cable attached while you push the
  box out on the rails.
* **Console Cables** - If you use serial consoles, keep a set of the cables in
  your bag.
* **USB Serial Adapter** - You never know when you need to console into the
  switch or NetApp.
* **C13 to C14 Power Cable** - This is an easy way to keep a box powered while
  you push it out of the rack, or as a way to power your laptop with the next
  adapter.
* **C14 to 5-15R Adapter/Cable** - When you google this, it will be obvious.
  Remember that there is a 99% likelihood that your laptop power supply will
  run on anything from 90-240V.

## Supplies

Supplies are consumable things that you use in the DC. These types of things
while they seem small make a huge difference.

* **Velcro** - Not zip ties, not wire ties, velcro. It comes in rolls and
  should be used liberally on cabling.
* **Label Tape** - Label makers are kinda worthless without this stuff. Always
  keep an extra one with the label maker.
* **Sharpies** - While they shouldn't be used to label things, sharpies are
  great for all sorts of things.

## Labeling

Since I label cables before I run them and generally label other things very
early on in their lifecycle, it only seems appropriate to start here. There
are a few schools of thoughts on how to label and what to label. All of those
things influence or are influenced by the label maker you use. The one thing
that us pretty universally true though, is that a bad label is worse than no
label at all.

### What to Label
This is completely dependent on the environment you work in. For me, I usually
default to labeling the racks themselves, anything that gets rack mounted, the
power infrastructure, ethernet cables, console cables and in some environments
power cables. My general rule is that if the specific port it ends up in
matters, it is probably worth labeling. I don't tend to label SAS and FC
interconnects but, ethernet cables are not generally even installed without
labels.

### How to Label
When talking about cables, there seems to be two basic camps, those who give
each cable an identifier and then use some corresponding document to identify
endpoints and those who label the endpoints. I fall into the label the
endpoints camp. The following are how I deal with each kind of thing.

* **Ethernet Cables (Including Console Cables)**
 * Label each end of the cable with the source and destination port along with
   device name. So, a cable that carries network will have a switch and port
   along with a host and port.
 * Using both names and two tab characters to separate them is roughly the
   right length to wrap the cable with the white space and have a flag hang off
   with one side being the dest and the other being the source.
 * Use eth[0-?] for onboard network interfaces, ipmi, ilo, mgmt, drac, etc. for
   baseboard management interfaces, pci <slot>.<interface> (i.e. pci 1.1, pci
   0.A) to describe additional network cards and the actual interface name on
   network gear (i.e. fa 0/10, gi 1/0/20, te 0/1) when describing ports.
  * The ethernet cable, not the adapter should get the label for console ports.
* **Power Infrastructure**
 * Use the naming standards that are discussed in the [Power](#Power) section
   to label each component.
  * In general, use the complete circuit name all the way to the strip.
 * The receptacle, the strip, CDU (if applicable) and the plug that is in the
   receptacle should all be labeled.
* **Systems and Racked Gear** 
 * Always label front and back.
** Should be easy to find when standing at the rack.
* **Racks**
 * Always label front and back.
 * Label the doors in addition to the rack frame if you have doors.

### Label Maker

The best thing I have found is the Brother TZ labelers. The nice thing about
these labelers is that the tape is inexpensive and it is easy to find label
makers at a reasonable price. If you watch the Office Depot and Staples ads,
there is usually a battery powered TZ label maker for $9.99 every few months.
Additionally, you can get label makers that you can connect to your workstation
and print them from some external datasource. I tend to use the TZ231 tape
almost exclusively, but if you had a need to color code things, it isn't hard
to get ahold of other colors.

## Cabling

Cabling is more of an art than a science. Not only is it an art, but it is
amazing how quickly a masterpiece can turn into the worst thing you have ever
seen. While I don't think that I can give a specific set of things that will
make it good, there are definitely a few things to consider that will help to
keep it from being bad.

### Cable Paths

Find a path and stick to it. I usually run power on one side of the rack and
then network & interconnect (SAS, IB, etc) cables on the other side. The best
thing you can do is define these paths with velcro. If it is easy to add new
cables to the path, they will end up there. Otherwise, you will end up with
someone thinking it is a good idea to go from the switch port to the system in
the center of the cabinet.

Cable paths are also important if you are running cables through the floor or
over the top of cabinets. If you follow standard paths, you are much less
likely to end up with a rats nest. Additionally, when you are in the floor,
this makes things predictable. I can't count the number of times I have seen
cables go from one end of the datacenter and take extremely divergent paths.

### Cable Management Brackets and Arms

The cable management brackets exist for two reasons. First, They make it easy
to find cables and move them around. Secondly, they keep excess pressure off of
the switch and system network ports. If you have more than 16 ports on a
switch, you need some sort of cable management. If you have 48 ports, you
should probably have 2U of cable management. Vertical cable management brackets
are great for cable paths, but on a dense chassis, having cable management
above and below makes a world of difference.

Cable management arms that get connected to systems are, interesting. It is
rare that I see seasoned admins actually use them. My general rule is, don't.
They look cool but are likely to obstruct airflow and just be a pain. I have
seen a few over the years that I like, but most of belong in the garbage.

### Color Coding

Color coding works well as long as people are committed to adhering to the
standard. The key is a standard that works for the given environment. For
example, if you color code on vlan and all your systems end up with trunks
carrying multiple vlans, it is likely that your color code won't be all that
useful. If instead you use colors to indicate primary and secondary uplinks
along with another color for management interfaces, you will likely gain value. 

## Power

Power in the datacenter is easily one of the least understood but most
important aspects of datacenter life. I am not going to claim I know everything
there is to know, but here are a few useful thoughts and tricks. This is not
intended to help you to actually understand how power works but more as a way
to do basic calculations about how screwed you are or are not.

### What is Load?

Load is where the conversation starts and ends. If a circuit has too much load,
it trips. On startup or heavy usage of systems, load increases. So, what is
load? Load is the amount of power in, amps, that a system is drawing at a given
time. Amps = Wattage/Voltage. So if I have a system with a single power supply
and it is using 240 watts on a 120 volt circuit, that system is drawing 2A of
power. If we move that same system to a 208V circuit, it is now drawing right
around 1.15A.

### How Much Load Can I Put On A Circuit?

The rule I use is 40%. Yes, you read that correctly, 40%. Why so low? First
off, in general, most breakers are not designed to carry more than 80% load for
any amount of time. Anytime you are consistently over 80% for more than a few
minutes, you are not in a good place. 

The second major assumption is that most systems have dual power supplies. Why
does that matter? In general, systems balance the load across the two power
supplies. So if a system needs 4A to run, each power supply is going to
responsible for 2A. If power is removed from one power supply, the other one
instantly picks up the load for both, increasing draw to 4A. 

Lets look at a scenario. We have 10 systems that each draw 4A total. Each of
these systems has dual power supplies, PS0 and PS1. Take PS0 on each system and
plug it into a 30A circuit and  do the same with PS1 on another 30A circuit.
That means we have 20A (4A/2 * 10 systems) on each circuit. That equates to
roughly 66% load on each circuit. If we remove power from one of the circuits,
the second circuit now needs to support 40A. Because they are 30A circuits, the
remaining circuit trips and now all 10 systems are down. If instead, we had
limited the circuits to 40% load or 6 systems, the failure of one circuit would
not have caused the corresponding circuit to fail.

### Circuit Sizing and Voltage

In most data centers that I have worked, you get a choice of 120V or 208V power
and 20A and 30A circuits. As a rule, I don't provision 120V circuits. You get
more bang for your buck at 208V when it comes time to the number of systems you
can fit on a single circuit. The key here is look at your requirements, if this
is a fairly static deployment, choose what is the most cost effective, if you
need long term growth, look at more power and flexibility.

### System Load

Figuring out what number to use for calculations on a system can be grey hair
inducing. I have never seen a fool proof way to decide on the load numbers that
should be assigned to a given system. In general, I use one of the following
approaches:

* Vendor Power Calculator and/or Specs - If using a vendor machine, they likely
  have typical power number available via a calculator or listed in the manual.
* 80% of Nameplate Load - This isn't great, but it gives ballpark load.
  Nameplate is the maximum listed on the nameplate of the power supply. So if
  it is a 1500W power supply, it is going to have a max load of 12.5A on a 120V
  circuit (Remember, A = W/V). This number is almost always high, but better
  safe than sorry.
* Measured Load Plus 10% - You can measure load using an amp meter and a cable
  that exposes the hot wire. I have a C13 to C14 cable that I will plug in,
  inline and measure load. The extra 10% gives a bit of wiggle room. This
  approach should work well if you measure when the system is fairly busy.

### Naming is Hard

As many of us already know, naming things is hard. What I call a PDU and my
coworker call a PDU may very well be different things. Make sure to confirm
that you, your colleagues and the electricians are on the same page with what
to call things. Below you will find my general rules on what to call things.

* CDU - Cabinet Distribution Unit - This is an intermediary control point. A
  CDU usually has multiple strips connected to it with each strip independently
  switched. I generally don't care for the use of CDUs as described above.
* Circuit - This corresponds to a single breaker in the panel. In the
  datacenter, it should only have one plug on it.
* Panel - The panel is where the circuits are terminated and the breakers live.
* PDU - Power Distribution Unit - This is the strip that systems connect to,
  assuming it is plugged directly into a circuit.

# Further Reading

* [Inside a Google Datacenter](http://www.google.com/about/datacenters/inside/streetview/)
