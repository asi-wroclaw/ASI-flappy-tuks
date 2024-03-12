# VerletEngine

Physics engine based on Verlet integration.

## Dependencies

Godot 3.2.1

## Properties
 
You can use following godot project properties:

* physics/Verlet/default_gravity: Vector2 Default gravity for vertexes. If not specyfied Vector2(.0,9.8) used.
* physics/Verlet/debug_grid: bool Draw vertexes and connections on screen. false by default.
* physics/Verlet/debug_statistics: bool Print amount of vertexes, connections and their process time on screen.

## Connection types:
* Linear: normal linear connection working like spring
* SingleTreshold: Works almost like Linear, but have 2 diffrend elasticity values choosed based on extenstion value
* DoubleTresholdLinear: Elasticity changes lineary beetwen two tresholds, otherwise constant

## Usage

Add VerletEngine.gd script as singleton to project to use.
This script does nothing by itself, it's only responsible for Verlet integration phisics simulataion for cloth simulation.

## TODO
* Rewrite c++/C#(slower but easier to integrate with engine) module for better performace
* Add LUT for connection elasticity(should be faster and more memory effective)

#Analitic geometry

Set of function for performing analitic gemetry operations.

## Dependencies

Godot 3.2.1

##Usage

Add AnaliticGeometry.gd script as singleton to project to use.
This script does nothing by itself, it's only liblary for performing analitic geometry operations for cloth simulator.