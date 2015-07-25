Very old remnant code fragments of mine from my old Demoscene days (<1993<). For personal nostalgia and backup purpose - Not sure that the floppy disks will still hold another 25 years :)

This repository contains a few surviving pieces of the code that I wrote during my PC demo coding time. After writing demos and cracktros (that's how you did learn bare metal coding at that time) on the Amstrad CPC, I moved to a PC where the demo development continued. It was really great fun ... Future Crew, Assembly, MOD sound files, real-time, bit and byte squeezing and µ seconds counting.

I remember well that I had quite some discussions with other coders from the #demoscene on the important question if it is required to write everything in assembler or if it's "allowed" to write the command dispatcher and boilerplate code in C (my position, still is) :-) Once, I even got refused the membership of a demo group because of my "lazy" opinion :)

The code in this repo contains the controller program in C and 2 assembler modules. The first draws a line between 2 points, as well draws and fills polygons. Everything based on 'integer' mathematics of course, since real-time floating point calculations where pure luxury reserved to people having a l33t i386 with a mathematical co-processor :) Putting pixels on the screen required a direct video memory access. Everything was hand-crafted.

The second assembler module implements arithmetical matrix calculations required to perform operations like rotation and shifting in the 3D space, as well as flattening 3D coordinates into the 2D space. Again, everything using 'integer' operations and 'integer' registers. The clue at this time was to have rainbow tables with pre-calculated sin/cos values of all angles. In order to write this in assembler, I first wrote the entire 'integer' based logic in C, which allowed me to do a quite linear conversion to assembler.

*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*+-+*

1993...

... and there was this ... stunning an entire generation of demo coders ... 

https://www.youtube.com/watch?v=rFv7mHTf0nA 

... From Wikipedia: Unreal ][ - The 2nd Reality (later known as Second Reality), is a demo created by Future Crew for the Assembly '93 demoparty. In the PC demo competition, Second Reality placed first with its demonstration of 2D and 3D rendering. The demo was released to the public in October 1993. It is considered to be one of the best demos created during the early 1990s on the PC, e.g. Slashdot voted it one of the "Top 10 Hacks of All Time."

Making of: https://www.youtube.com/watch?v=LIIBRr31DIU
