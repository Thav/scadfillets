rotatePoint = (p1,p0,angle) ->
  #Apply rotation matrix to p1 with respect to p0
  #Could probably be written more compactly, but oh well
  s = Math.sin(angle)
  c = Math.cos(angle)
  p1[0] -= p0[0]
  p1[1] -= p0[1]
  p2 = [0,0]
  p2[0] = p1[0]*c - p1[1]*s
  p2[1] = p1[0]*s + p1[1]*c
  p1[0] = p2[0]+p0[0]
  p1[1] = p2[1]+p0[1]
  p1

pointDistance = (p1,p2) ->
  #Root sum square on the coordinates of p1 and p2 to find the
  #scalar distance between them
  dx = p1[0]-p2[0]
  dy = p1[1]-p2[1]
  ss = Math.pow(dx,2)+Math.pow(dy,2)
  rss = Math.sqrt(ss)
  rss

locateFilletArcCenter = (p1,p2,p3,r) ->
    #Translate points to origin (p0) with respect to p1
  p0 = [0,0]
  p2t = [p2[0]-p1[0],p2[1]-p1[1]]
  p3t = [p3[0]-p1[0],p3[1]-p1[1]]
  log.debug("Translated Points #{p2t[0]},#{p2t[1]} #{p3t[0]},#{p3t[1]}")
  #Rotate points to fit in reference frome of p2 being on the positive x axis
  aref = Math.atan2(p2t[1],p2t[0])
  p2r = rotatePoint(p2t,p0,-aref)
  p3r = rotatePoint(p3t,p0,-aref)
  #Now the angle from p3 in the new reference frame gives the angle between the points
  theta = Math.atan2(p3t[1],p3t[0])/2
  log.debug("Rotated points #{p2r[0]},#{p2r[1]} #{p3r[0]},#{p3r[1]}")
  log.debug("Rotated angle #{aref*180/Math.PI} Bisected angle #{theta*180/Math.PI}")
  #Find shortest common distance between the pivot and the other points
  d = Math.min(pointDistance(p2t,p0),pointDistance(p3t,p0))
  #Find max radius
  rmax = Math.abs(d*Math.tan(theta))
  #Set radius if given and valid, and redefine d to make calculations work out
  if r <= 0 or r > rmax
    r = rmax
  else
    d = Math.abs(r/Math.tan(theta))
  #Work out distance from pivot to circle's center, make point, then rotate and translate back
  l = Math.sqrt(Math.pow(d,2)+Math.pow(r,2))
  log.debug("drl #{d} #{r} #{l}")
  p4r = [l,0]
  p4t = rotatePoint(p4r,p0,aref+theta)
  p4 = [p4t[0]+p1[0], p4t[1]+p1[1]]
  #Use new r and d to calculate the end points of the fillets
  p2p = rotatePoint([d,0],p0,aref)
  p2p = [p2p[0]+p1[0],p2p[1]+p1[1]]
  p3p = rotatePoint([d,0],p0,aref+2*theta)
  p3p = [p3p[0]+p1[0],p3p[1]+p1[1]]
  [r,p4,p2p,p3p]

class insideFillet extends Part
  constructor:(options)->
    @defaults = {p1:[0,0],p2:[1,0],p3:[0,1],r:0,h:1}
    options = @injectOptions(@defaults, options)
    super options
    
    [@r,p4,p2p,p3p] = locateFilletArcCenter(@p1,@p2,@p3,@r)
    log.debug("p2p,p3p #{p2p[0]},#{p2p[1]} #{p3p[0]},#{p3p[1]}")
    #Create triangular prism from which to subtract a cylinder for the fillet
    @poly = CAGBase.fromPoints([@p1,p2p,p3p])
    @prism = @poly.extrude({offset:[0,0,@h]})
    #Create cylinder, subtract from prism and profit
    @cyl = new Cylinder({r:@r,h:@h}).translate([p4[0],p4[1]])
    @prism.subtract(@cyl)
    @union(@prism)
    
class cubeNegativeFillet extends Part
  constructor:(options)->
    @defaults = {size:[10,10,10],radius:0,vertical:[3,3,3,3],top:[0,0,0,0],bottom:[0,0,0,0],fn:0,vertical_fn:[0,0,0,0],top_fn:[0,0,0,0],bottom_fn:[0,0,0,0]}
    options = @injectOptions(@defaults, options)
    super options
    
    if @fn > 0
      @vertical_fn = [@fn,@fn,@fn,@fn]
      @top_fn      = [@fn,@fn,@fn,@fn]
      @bottom_fn   = [@fn,@fn,@fn,@fn]
      
    j = [1,1,-1,-1,1]
    
    negCube = new Part()
    zedges = []
    yedges = []
    xedges = []
    
    for i in [0..3]
      #if @radius > 0
      zedges[i] = new insideFillet
              p1:[@size[0]*j[i+1]/2,@size[1]*j[i]/2]
              p2:[@size[0]*j[i+1]/2,0]
              p3:[0,@size[1]*j[i]/2]
              r:@radius
              h:@size[2]
        .translate([0,0,-@size[2]/2])
      negCube.union(zedges[i])
      
      yedges[i] = new insideFillet
              p1:[@size[0]*j[i+1]/2,@size[2]*j[i]/2]
              p2:[@size[0]*j[i+1]/2,0]
              p3:[0,@size[2]*j[i]/2]
              r:@radius
              h:@size[1]
          .rotate([90,0,0])
          .translate([0,@size[1]/2,0])
      negCube.union(yedges[i])
      
      xedges[i] = new insideFillet
              p1:[@size[2]*j[i+1]/2,@size[1]*j[i]/2]
              p2:[@size[2]*j[i+1]/2,0]
              p3:[0,@size[1]*j[i]/2]
              r:@radius
              h:@size[0]
          .rotate([0,90,0])
          .translate([-@size[0]/2,0,0])
      negCube.union(xedges[i])
    @union(negCube)

class cubeFillet extends Part
  constructor:(options)->
    @defaults = {size:[10,10,10],radius:0,vertical:[3,3,3,3],top:[0,0,0,0],bottom:[0,0,0,0],fn:0,vertical_fn:[0,0,0,0],top_fn:[0,0,0,0],bottom_fn:[0,0,0,0]}
    options = @injectOptions(@defaults, options)
    super options
    
    base = new Cube({size:@size,center:true})
    base.subtract(new cubeNegativeFillet({size:@size,radius:@radius,vertical:@vertical,top:@top,bottom:@bottom,fn:@fn,vertical_fn:@vertical_fn,top_fn:@top_fn,bottom_fn:@bottom_fn}))
    @union(base)

class filletPlank extends Part
  constructor:(options)->
    @defaults = {size:[2,1,1]}
    options = @injectOptions(@defaults, options)
    super options
    
    [x,y,r] = @size
    @plank = new Cube({size:[x-r,y,r],center:true}).translate([-r/2,0,0])
    @fil = new insideFillet({p1:[0,0],p2:[r,0],p3:[0,r],h:y})
    @fil.rotate([-90,0,0]).translate([x/2-r,-y/2,r/2])
    @plank.union(@fil)
    @union(@plank)
    
class filletPlate extends Part
  constructor:(options)->
    @defaults = {}
    options = @injectOptions(@defaults, options)
    super options
    
    [x,y,r] = @size
    plank1 = new filletPlank({size:[x,y,r]})
    plank2 = new filletPlank({size:[x,y,r]}).rotate([0,0,180])
    plank3 = new filletPlank({size:[y,x,r]}).rotate([0,0,90])
    plank4 = new filletPlank({size:[y,x,r]}).rotate([0,0,-90])
    plank1.intersect([plank2,plank3,plank4])
    @union(plank1)
    
class cubePositiveFillet extends Part
  constructor:(options)->
    @defaults = {size:[10,10,10],radius:0,front:null,back:null,left:null,right:null,top:null,bottom:null,fn:0,vertical_fn:[0,0,0,0],top_fn:[0,0,0,0],bottom_fn:[0,0,0,0]}
    options = @injectOptions(@defaults, options)
    super options
        
    posCube = new Cube({size:@size,center:true})
    zedges = []
    yedges = []
    xedges = []
    [x,y,z] = @size
    if @radius is 0 then @radius = Math.min(x/2,y/2,z/2)
    
    if @top?
      if @top is 0 then @top = @radius
      topPlate = new filletPlate({size:[x+2*@top,y+2*@top,@top]}).translate([0,0,z/2-@top/2])
      posCube.union(topPlate)
    
    if @bottom?
      if @bottom is 0 then @bottom = @radius
      bottomPlate = new filletPlate({size:[x+2*@bottom,y+2*@bottom,@bottom]}).rotate([180,0,0]).translate([0,0,-z/2+@top/2])
      posCube.union(bottomPlate)
      
    @union(posCube)
    
class cylinderPositiveFillet extends Part
  constructor:(options)->
    @defaults = {fradius:0,face:null,top:null,bottom:null,$fn:0,vertical_fn:[0,0,0,0],top_fn:[0,0,0,0],bottom_fn:[0,0,0,0]}
    options = @injectOptions(@defaults, options)
    super options
        
    @posCyl = new Cylinder({r:@r,h:@h,center:true,$fn:@$fn})
    zedges = []
    yedges = []
    xedges = []
    if @fradius is 0 then @fradius = Math.min(@h/2,@r)
    @theta = 360/@$fn
    @r = @r*Math.cos(Math.PI*@theta/(2*180))
    
    if @top?
      if @top is 0 then @top = @fradius
      @topPlate = []
      for i in [0...@$fn]
        if i is 0
          @topPlate[i] = new filletPlank({size:[2*@r+2*@top,2*@r+2*@top,@top]}).translate([0,0,@h/2-@top/2]).rotate([0,0,@theta*(.5+i)])
        else
          @topPlate[i] = @topPlate[i-1].clone().rotate([0,0,@theta])
      @topPlate[0].intersect(@topPlate[1...@$fn])
      @posCyl.union(@topPlate[0])
    
    if @bottom?
      if @bottom is 0 then @bottom = @fradius
      @bottomPlate = []
      for i in [0...@$fn]
        if i is 0
          @bottomPlate[i] = new filletPlank({size:[2*@r+2*@bottom,2*@r+2*@bottom,@bottom]}).translate([0,0,@h/2-@bottom/2]).rotate([180,0,@theta*(.5+i)])
        else
          @bottomPlate[i] = @bottomPlate[i-1].clone().rotate([0,0,@theta])
      @bottomPlate[0].intersect(@bottomPlate[1...@$fn])
      @posCyl.union(@bottomPlate[0])
     
    @union(@posCyl)
    
include "test.coffee"
