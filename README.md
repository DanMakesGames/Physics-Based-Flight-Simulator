# Physics Based Flight Simulator
This is a physics based flight Simulator which simulates airfoils(wings) and control surfaces accurately. I was originally planning on turning this into a networked game, so please excuse left over networking code.

### Video
https://streamable.com/v6j5dh

### Airfoils(wings) model
* Linear lift curve, based on Angle of Attack.
* Angle of attack limits (stalling).
* Air Drag.
* Camber, which is used to simulate control surfaces.

### Notable Files
[`FlightModelV1.gd`](FlightModelV1.gd): Represents the airplane's body.
['Airfoil.gd'](Airfoil.gd): Represents a wing with a control surface.

### Sources
* https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/learn-about-aerodynamics/
* http://airfoiltools.com/airfoil/details?airfoil=p51droot-il#polars
* http://brennen.caltech.edu/fluidbook/