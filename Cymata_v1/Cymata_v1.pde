/*

 Cymata - v1
 
 Assembled by Matt Schroeter and Tim Rolls as part of Art Not Ads - artnotads.org
 
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
import java.awt.event.*;


Minim minim; 
AudioPlayer player;
AudioInput in;
FFT fft;

ControlP5 cp5;

HE_Mesh mesh;
HE_Mesh modifiedMesh;
WB_Render render;
WB_Plane P;

float[][] vertices;
float[][] values=new float[1024][1024];

float depth = -1000;
int multiplier = 1;
int uSize=30;
int vSize=30;

// presentation
color bgcolor = color(230,230,230);    // background color
color shapecolor = color(255);                      // shape color
boolean facesOn = true;                // toggle display of faces
boolean edgesOn = true;                // toggle display of edges

//Subdivision and Modifiers
HEM_Smooth smoothMod=new HEM_Smooth();
boolean smoothing = false;             //toggle smoothing subdivider
HEM_Spherify sphereMod=new HEM_Spherify();
boolean sphereBool = false;
HEM_SphereInversion invMod=new HEM_SphereInversion();
boolean invBool = false;
WB_Line L;
HEM_Twist twistMod=new HEM_Twist();
boolean twistBool = false;

//used to multiply displacement
int zValue;

String timestamp;                      // timestamp to distinguish saves

void setup() {
  size(1280, 720, OPENGL);
  hint(ENABLE_OPENGL_4X_SMOOTH);
  smooth();
  
  //mouse zoom setup
  addMouseWheelListener(new MouseWheelListener() { 
    public void mouseWheelMoved(MouseWheelEvent mwe) { 
      mouseWheel(mwe.getWheelRotation());
  }}); 
  
  // Control P5 Setup
  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false);
  zValue = 3;
  Slider s1=cp5.addSlider("zValue", 3, 20, 20, 20, 20, 200);
  Slider s2=cp5.addSlider("multiplier", 3, 60, 88, 20, 20, 200);
  cp5.addToggle("facesOn",20,260,63,15).setLabel("Toggle Faces");
  cp5.addToggle("edgesOn",88,260,64,15).setLabel("Toggle Edges");
  cp5.addToggle("smoothing",20,400,63,15).setLabel("Smoothing");
  cp5.addToggle("sphereBool",88,400,63,15).setLabel("Sphere");
  cp5.addToggle("twistBool",20,450,63,15).setLabel("Twist");  
  cp5.addToggle("invBool",88,450,63,15).setLabel("Invert");

  // Minim setup
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 1024);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  
  //modifier setup

  sphereMod.setRadius(50);
  sphereMod.setCenter(50, 0, 0);
  
  invMod.setRadius(50);
  invMod.setCenter(50, 0, 0);
  //also accepts a WB_Point
  invMod.setCutoff(1000);// maximum distance outside the inversion sphere
  invMod.setLinear(false);// if true, mirrors a point across the sphere surface instead of a true spherical inversion
  
  smoothMod.setIterations(8);
  smoothMod.setAutoRescale(true);// rescale mesh to original extents

  
//  //Create a 10 by 10 grid of cells (11 x 11 points)
//  HEC_Grid creator=new HEC_Grid();
//  creator.setU(10);// number of cells in U direction
//  creator.setV(10);// number of cells in V direction
//  creator.setUSize(300);// size of grid in U direction
//  creator.setVSize(500);// size of grid in V direction
//  creator.setWValues(values);// displacement of grid points (W value)
//  mesh=new HE_Mesh(creator);
//  
//  //Get all vertices as float[3] (x,y,z)
//  vertices=mesh.getVerticesAsFloat();
//  
//  render=new WB_Render(this);
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
  
  for (int j = 0; j < fft.specSize(); j++) {
    for (int i = 0; i < fft.specSize(); i++) {
      values[i][j]=multiplier*fft.getBand(i)*noise(multiplier*fft.getBand(i),multiplier*fft.getBand(j));
    }
  }

  //create Grid to displace
  HEC_Grid creator=new HEC_Grid();
  creator.setU(uSize);// number of cells in U direction
  creator.setV(vSize);// number of cells in V direction
  creator.setUSize(uSize*10);// size of grid in U direction
  creator.setVSize(vSize*10);// size of grid in V direction
  creator.setWValues(values);// displacement of grid points (W value)
  // alternatively this can be left out (flat grid). values can also be double[][]
  // or and implementation of the WB_Function2D<Double> interface.
  mesh=new HE_Mesh(creator);
  
    if (smoothing) {
    mesh.modify(smoothMod);
  }
  
  if (sphereBool) {
     mesh.modify(sphereMod);
  }
  
   if (invBool) {
     mesh.modify(invMod);
  }
  
     if (twistBool) {
     L=new WB_Line(100,0,0,100,0,1);
  twistMod.setTwistAxis(L);// Twist axis
  //you can also pass the line as two points:  modifier.setBendAxis(0,0,-200,1,0,-200)
  
  twistMod.setAngleFactor(.51);// Angle per unit distance (in degrees) to the twist axis
  // points which are a distance d from the axis are rotated around it by an angle d*angleFactor;
  
  L=new WB_Line(-200+mouseX*0.5,0,0,-200+mouseX*0.5,0,1);
  twistMod.setTwistAxis(L);
  twistMod.setAngleFactor(mouseY*0.005);
  
  mesh.modify(twistMod);
     
  }
    
  
  // Start Custom Modifier Parameters
    
    //Export the faces and vertices
    float[][] vertices = mesh.getVerticesAsFloat(); // first index = vertex index, second index = 0..2, x,y,z coordinate
    int [][] faces = mesh.getFacesAsInt();// first index = face index, second index = index of vertex belonging to face
     
    //Do something with the vertices, x, y, z
    for(int i=0;i<mesh.numberOfVertices();i++){
//     vertices[i][0]*=5*cos(noise(HALF_PI/10*cos(i)*QUARTER_PI)); 
//     vertices[i][1]*=5*sin(HALF_PI/100*i*QUARTER_PI);
//     vertices[i][2]*=zValue+100*sin(HALF_PI/10*cos(i)*noise(PI));
     vertices[i][0]*=zValue+100*sin(HALF_PI/10*cos(i)*noise(PI));
     vertices[i][1]*=zValue+100*sin(HALF_PI/10*cos(i)*noise(PI));
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
  
  //controls for rendering based on GUI
  if (facesOn) {    //toggle faces
    noStroke();
    fill(shapecolor);
    render.drawFaces(mesh);
  }
  if (edgesOn) {    //toggle edges 
    stroke(0);
    if(edgesOn&&!facesOn){  //Change stroke to white, if no faces 
      stroke(255);
    }
    render.drawEdges(mesh);
  }
   
  
    
//updateGrid();
 
}

void keyPressed()
{
   // save a single screenshot
  if (key == 's') {
    timestamp = year() + nf(month(),2) + nf(day(),2) + "-"  + nf(hour(),2) + nf(minute(),2) + nf(second(),2);
    save("output/screenshots/" + timestamp + ".png");
  }
  
  //change grid size with arrow keys
  if (key == CODED) {
    if (keyCode == UP) {
      vSize+=10;
    } else if ((keyCode == DOWN)&&vSize>10) {
      vSize-=10;
    } else if (keyCode == RIGHT) {
      uSize+=10;
    } else if ((keyCode == LEFT)&&uSize>10) {
      uSize-=10;
    }  
  }
}

//scroll zoom
void mouseWheel(int delta) {
  depth+=(delta*10); 
}

void updateGrid(){
//  Change float[3] vertices
//  for(float[] v: vertices){
//     v[2]=200*noise(10+0.004*v[0],10+0.005*v[1],0.0035*frameCount); 
     
     for(int i=0;i<mesh.numberOfVertices();i++){
//     vertices[i][0]+=5*cos(noise(HALF_PI/(zValue*200)*cos(i)*QUARTER_PI)); 
//     vertices[i][1]+=5*sin(HALF_PI/(zValue*200)*i*QUARTER_PI);
     vertices[i][0]+=zValue*20*sin(HALF_PI/10*cos(i)*noise(PI)); 
     vertices[i][1]+=zValue*10*sin(HALF_PI/10*cos(i)*noise(PI));
     vertices[i][2]+=zValue+5*sin(HALF_PI/10*cos(i)*noise(PI));
    }
  
  //Plug them back into the mesh
  mesh.setVerticesFromFloat(vertices);
}

void stop()
{
  // always close Minim audio classes when you are done with them
  minim.stop();
  super.stop();
}


