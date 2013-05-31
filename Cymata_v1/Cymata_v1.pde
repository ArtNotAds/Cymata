/*

 Cymata - v1
 
 Assembled by Matt Schroeter as part of Art Not Ads - artnotads.org
 
 May, 2013
 
 This release uses these libraries: Hemesh for 3D visualization, Minim for sound analysis, and ControlP5.
 The sound analysis is working live off line-in. 
 
 3 sliders control the sensitivity of the audio to x,y,z arrays for the shape.
 
*/

import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.analysis.*;

import wblut.math.*;
import wblut.processing.*;
import wblut.core.*;
import wblut.hemesh.*;
import wblut.geom.*;

import controlP5.*;

import processing.opengl.*;


Minim minim; 
AudioPlayer player;
AudioInput in;
FFT fft;

ControlP5 cp5;

HE_Mesh mesh;
HE_Mesh modifiedMesh;
WB_Render render;
WB_Plane P;

float depth = -2000;

int xValue;
int yValue;
int zValue;

void setup() {
  size(1000, 1000, OPENGL);
  hint(ENABLE_OPENGL_4X_SMOOTH);
  smooth();
  
  // Control P5 Setup
  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false);
  xValue = 3;
  yValue = 3;
  zValue = 3;
  Slider s1=cp5.addSlider("xValue", 3, 20, 20, 60, 20, 200);
  Slider s2=cp5.addSlider("yValue", 3, 20, 80, 60, 20, 200);
  Slider s3=cp5.addSlider("zValue", 3, 20, 140, 60, 20, 200);
 
  // Minim setup
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 1024);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  
  
  
  
}

void draw() {
  background(0);
  lights();
  cp5.draw();
  //audio calling & limits
  fft.forward(in.mix);
  fft.window(FFT.HAMMING);
  float threshold = 100;
  float leftLevel = in.left.level();
  float rightLevel = byte(in.right.level());

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
     vertices[i][0]*=xValue+2*cos(noise(HALF_PI/10*cos(i)*QUARTER_PI)); 
     vertices[i][1]*=yValue+2*sin(HALF_PI/100*i*QUARTER_PI);
     vertices[i][2]*=zValue+100*sin(HALF_PI/10*cos(i)*noise(PI));
    }
     
    //Use the exported faces and vertices as source for a HEC_FaceList
    HEC_FromFacelist faceList=new HEC_FromFacelist().setFaces(faces).setVertices(vertices);
    modifiedMesh=new HE_Mesh(faceList);
    
    // End Custom Modifier Parameters
  
  //Render mesh with positioning
  
  render=new WB_Render(this);
 
  translate(width/2,height/2, depth);
  rotateY(mouseX*1.0f/width*TWO_PI);
  rotateX(mouseY*1.0f/height*TWO_PI);
  
  noStroke();
  fill(255);
  
  render.drawFaces(modifiedMesh);
  stroke(0);
  //render.drawEdges(modifiedMesh);
 
}

void keyPressed()
{
  
}

void stop()
{
  // always close Minim audio classes when you are done with them
  minim.stop();
  super.stop();
}


