# ClothSimulation

Cloth simulation for Godot. Created to make realistic cloaks in my project.
Sadly not very user friendly, I'm quite new and dunno how to integrate some feauters with editor. There are settuped as Script variables

![screenshots](https://raw.githubusercontent.com/TakMashido/Godot-cloth-simulation/master/screenshots/Godot_v3%202020-07-29%2013-44-17-08.png)

## Dependencies

[Godot 3.2.1](https://godotengine.org)

## Usage

### Demo
Download reposity and load it as project in godot.
Open Test1.tscn(showcase) or Test2.tscs(Benchmark) under ClothSimulation dir and press f6 to run.

### In project use
2. Add cloth node
  1. Add Polygon2d to scene, and att VerletPolygon.gd script to it.
  2. In Polygon2D uv editor setup points and add Polygons, Script will automaticly setup desired Verlet simulation and update polygon points position with simulation resoults.
  3. Set up Static verticles script variable to anchor desired points.  
  (check index of desired vertexes e.g in data/uv of polygon and add to parameter list)

### Documentation

Code documention stored in VerletPolygon/VerletPolygon.md file.

## TODO
* Add option to interpolate only edges: smaller amunt of vertices is barery visible on places with lesser amount of details, making so will increase performace by decreasing number of vertices and connections without big quality decrease 
* Add weight to simulated vertices  
* Rewrite verlet engine as c++/C#(slower but easier to integrate with engine) module for better performace
* Add tool mode based creator(make nxm grid), and interpolation in tool mode
* Divide connections and points into chunks to be able to stop processing then when there are out of screen.
