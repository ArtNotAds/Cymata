/*

 Cymata - v1
 
 Assembled by Matt Schroeter as part of Art Not Ads - artnotads.org
 
 May, 2013
 
 This release uses these libraries: Hemesh for 3D visualization, Minim for sound analysis, and Nervous System's OBJ export.
 The sound analysis is working live off of an imported file - can be configured to respond to line-in. 
 
 Pressing 'k' plays the sound file.
 
 Still experimenting with configuring hemesh and exporting 3D files. Will be adding some interface elements in the near future. 
 
*/

import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;

import wblut.math.*;
import wblut.processing.*;
import wblut.core.*;
import wblut.hemesh.*;
import wblut.geom.*;


import ddf.minim.analysis.*;
import processing.opengl.*;
import nervoussystem.obj.*;

Minim minim; 
AudioPlayer player;
AudioInput in;
AudioSample kick;
FFT fft;    

HE_Mesh mesh;
HE_Mesh modifiedMesh;
WB_Render render;
WB_Plane P;

float depth = -1000;

boolean record = false;

void setup() {
  size(1000, 1000, OPENGL);
  minim = new Minim(this);
  //in = minim.getLineIn(Minim.STEREO, 1024);
  kick = minim.loadSample("Pylons.mp3", 1024);
  fft = new FFT(kick.bufferSize(), kick.sampleRate());
  smooth();
  //background(255);
}

void draw() {
  background(0);
   lights();
   
   // OBJ recording
   if (record) {
    beginRecord("nervoussystem.obj.OBJExport", "filename-####.obj"); 
  } 
   //audio calling & limits
  fft.forward(kick.mix);
  fft.window(FFT.HAMMING);
  float threshold = 100;
  float leftLevel = kick.left.level();
  float rightLevel = byte(kick.right.level());

  if (leftLevel > threshold) {              
    leftLevel = threshold;
  }
  if (rightLevel > threshold) {
    rightLevel = threshold;
  }
  
  float[][] values=new float[1024][1024];
  for (int j = 0; j < fft.specSize(); j++) {
    for (int i = 0; i < fft.specSize(); i++) {
      values[i][j]=20*fft.getBand(i)*noise(0.5*fft.getBand(i),0.5*fft.getBand(j));
    }
  }

  HEC_Grid creator=new HEC_Grid();
  creator.setU(40);// number of cells in U direction
  creator.setV(40);// number of cells in V direction
  creator.setUSize(500);// size of grid in U direction
  creator.setVSize(500);// size of grid in V direction
  creator.setWValues(values);// displacement of grid points (W value)
  // alternatively this can be left out (flat grid). values can also be double[][]
  // or and implementation of the WB_Function2D<Double> interface.
  mesh=new HE_Mesh(creator);
  
  // Start Custom Modifier Parameters
    
    //Export the faces and vertices
    float[][] vertices = mesh.getVerticesAsFloat(); // first index = vertex index, second index = 0..2, x,y,z coordinate
    int [][] faces = mesh.getFacesAsInt();// first index = face index, second index = index of vertex belonging to face
     
    //Do something with the vertices, x, y, z
    for(int i=0;i<mesh.numberOfVertices();i++){
     vertices[i][0]*=2+2*cos(HALF_PI/100*i+HALF_PI); 
     vertices[i][1]*=2+2*sin(HALF_PI/10*i+QUARTER_PI);
     vertices[i][2]*=2+2*cos(HALF_PI/10*i);
    }
     
    //Use the exported faces and vertices as source for a HEC_FaceList
    HEC_FromFacelist faceList=new HEC_FromFacelist().setFaces(faces).setVertices(vertices);
    modifiedMesh=new HE_Mesh(faceList);
    
    // End Custom Modifier Parameters
  

  render=new WB_Render(this);
 
  translate(width/2,height/2, depth);
  rotateY(mouseX*1.0f/width*TWO_PI);
  rotateX(mouseY*1.0f/height*TWO_PI);
  noStroke();
  fill(255);
  //render.drawFaces(mesh);
  render.drawFaces(modifiedMesh);
  stroke(0);
  //render.drawEdges(mesh);
  //render.drawEdges(modifiedMesh);
  

}

void keyPressed()
{
  if ( key == 'k' ) kick.trigger();
  //if (key == 'e')  HET_Export.saveToSTL(modifiedMesh,sketchPath("boom.stl"),1.0);
  if (key == 'e') record = true;
  if (key == 'f') {
    endRecord();
    record = false;
  }
}

void stop()
{
  // always close Minim audio classes when you are done with them
  kick.close();
  minim.stop();
  
  super.stop();
}


