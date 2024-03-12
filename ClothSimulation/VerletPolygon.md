# VerletPolygon documentation

Godot version: 3.2.1

## Script Variables

### Static vertices:
Vertices wchich are not moved by simulation itself instead they move with object global position.

#### Displaced static
Every vertex witch diffrend UV and Polygon position is made static.

#### Static vertices
Additional list to provide new static vertices. Each entry is id of vertex wchich you want to anchor. Check it in Polygon or uv property of Polygon2D under data category.
You can also add negative entries to ignore vertices during adding new static from displacement.

### Additional connections
Array of lists of vetices indexes(lookup static vertices) beetwen wich you want to add extra connections.  
Each entry is treated as polygon so [1,4] add connection beetwen 1-4, and [3,7,1] adds 3-7, 1-7 and 1-3.

### Visual settings:
Setting influencing Polygon apperence.

#### XSort, YSort
Sort polygons to ensure right draw order and simulate deph.
Soring use uv coordinates.
Possible values:
* None: Given axist not taken into account during sorting. If both axis None orginal order of polygons is preserved.
* Forward: Vertices with bigger axis value are drawed first. This makes them apper behind. If both Forward upper left corner of texture on top.
* Backward: Vertices with smaller axis value are drawed first. This makes them apper behind. If both Backward bottom right corner of texture on top.

#### Interpolation steps
How many times interpolate polygon for more simulation details.
Each step doubles vertex count, and triples connections number.
1 should be enought for most cases, use 2 for bigger elements(quater of screen or more).
Warning it's increasing computation time almost 3 times by doubling vertexes number and increasing connections number 4 times.
Also structures with more connections appers heavier, are more streched, you should consider using y scale for hindig this effect(adding vertices weight in todo list should be fixed later).

#### Smooth interpolation
Adjust static vertexes position to form smoother line. If false new vertices added directly in middle of space beetwen them.

### Physics

#### Connection type
Connections used by simulation.
Check connection types in VerletEngine.

#### Compress elasticity
Strength of connection, affect how fast connections go back to it's orginal length when shortened. Smaller values are more rubbery.
#### Strech elasticity
Strength of connection, affect how fast connections go back to it's orginal length when streched. Smaller values are more rubbery.
#### Compression treshold
Used by DoubleTresholdLinear connections to determine when start interpolating elascity.z
How many times connection have to be extended to use strech elasticity instead of compress elasticity.

## Cloth creation

Add VerletEngine/VerletEngine.gd as singleton to your project.
You should also set multithreaded physics2d simulation in godot settings becouse, processing large numbers of point's and connections is computionally expensive. 
Verlet integration by itself will run on single thread, but other element's will not run on this heavy cluttered thread.

Next add VerletPolygon.gd Script to Polygon2d node wchich you want to change into animated cloth.
Setup vertices in uv editor of polygon. UV map is used for orginal points location affecting their connections lengths.
To setup cloth shape change points position, they will be made static.
You also have to setup polygons - connections are taken from their sites.

The best effects gives texture with semi transparent bounds, otherwise big aliasing will be visible, antialiasing from polygon2d do not work there.