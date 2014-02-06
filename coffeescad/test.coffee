pointMarker = (p) -> cylinder({r1:.75,r2:0,h:10}).color([.1,.15,.1]).translate([p.x,p.y])

class Point
  constructor: (@x,@y,@z=0) ->

log.level=log.DEBUG

testPoints = () ->
  P1 = new Point(0,0)
  P2 = new Point(10,0)
  P3 = new Point(0,20)
  #assembly.add(new pointMarker(P1))
  #assembly.add(new pointMarker(P2).color([.1,.7,.1])) #Green
  #assembly.add(new pointMarker(P3).color([.5,.5,.1])) #Yellow

testInsideFillet = () ->
  fil = new insideFillet({p1:[-5,-10],p2:[-5,0],p3:[0,-10],r:0})
  assembly.add(fil.color([.3,.6,.9]))
  cubef = new cubeFillet({size:[10,20,15],radius:3})
  assembly.add(cubef)

testMisc = () ->
  fil1 = new insideFillet({p1:[0,0],p2:[5,0],p3:[0,5],h:15}).rotate([0,90,0]).color([.2,.83,.12])
  fil2 = new insideFillet({p1:[0,0],p2:[5,0],p3:[0,5],h:15}).rotate([90,180,0]).translate([5,5,0])
  #assembly.add(fil1)
  #assembly.add(fil2)

testCubePosFillet = () ->
  assembly.add(new cubePositiveFillet({size:[20,15,10],radius:3,top:0,bottom:0}).translate([20,0,0]))
  
testFilletPlank = () ->
  assembly.add(new filletPlank({size:[15,10,3]}))
  
testFilletPlate = () ->
  assembly.add(new filletPlate({size:[15,10,3]}).translate([0,20,0]))
  
cylinderPosFillet = () ->
  assembly.add(new cylinderPositiveFillet({r:5,h:10,fradius:3,top:0,bottom:0,$fn:10}).translate([-20,0,0]))
  
#testFilletPlank()
#testFilletPlate()
#testCubePosFillet()
#cylinderPosFillet()