import quickhull3d.*;
import ComputationalGeometry.*;
import processing.video.*;

/*** MAPPING THE BLACK MASKS***/
import deadpixel.keystone.*;
Keystone ks;

CornerPinSurface[] face = new CornerPinSurface[3];
PGraphics[] faceTextures = new PGraphics[3];
PImage[] shade = new PImage[3];



/*** OSC ***/
import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation;
int pushCount = 0;


/*** SOUND ***/
import ddf.minim.*;  // Imports Minim, a library for playing sound
Minim minim;        // Creates an object called minim from the class Minim
AudioSample kick;    // In Minim, AudioSample is the variable type for an audio sample player
AudioSample snare;   // here we have made two AudioSample variables named kick and snare


/*** CLIPPING MASK FOR BACKGROUND ***/

//int currShape = 0;
//int numShapes = 2;

int leftClipIndex = 0;
int rightClipIndex = 0;


String[] leftMovieFilenames = new String[]{"testgreen.mov", "testblue.mov"};
String[] rightMovieFilenames = new String[]{"testred.mov", "testyellow.mov"};
String mappingSide = "LEFT";

ClippingMask[] leftClips = new ClippingMask[leftMovieFilenames.length];
ClippingMask[] rightClips = new ClippingMask[rightMovieFilenames.length];

boolean calibrate = false;


void setup(){
  size(1024,800,P3D);
  
  
  /*** SETUP: CLIPPING MASKS FOR VIDEOS ***/
  textSize(18);
  
  for (int i = 0; i < leftMovieFilenames.length; i++) {
    leftClips[i] = new ClippingMask(this, leftMovieFilenames[i], "clipLeft.json", 0);
  }

  for (int i = 0; i < rightMovieFilenames.length; i++) {
    rightClips[i] = new ClippingMask(this, rightMovieFilenames[i], "clipRight.json", 0);
  }
  
  /*** SETUP: KEYSTONE FOR BLACK MASKS ***/
  ks = new Keystone(this);
 
 for(int i=0; i<face.length; i++){
    face[i]= ks.createCornerPinSurface(200,50,20);
    faceTextures[i] = createGraphics(200, 50, P2D);
    shade[0] = loadImage("blackmask.png");
    shade[1] = loadImage("blackmask.png");
    shade[2] = loadImage("blackmask.png");
  }
  
  smooth();


   /*** SETUP: TOUCH OSC***/ 
  frameRate(25);
  oscP5 = new OscP5(this,12000);
  myRemoteLocation = new NetAddress("192.168.1.139",12000);
  
  
   /*** SETUP: SOUND***/ 
  minim = new Minim(this);  // fills the variable minim with a new object Minim
  kick = minim.loadSample("BD.mp3", 512);  // note: 512 is the buffer rate and should not be changed
  snare = minim.loadSample("SD.wav", 512);


}

  /*** END OF SETUP ***/ 


void movieEvent(Movie m) {
  m.read();
}

void delay(int ms) {
  int time = millis() + ms;
  while (millis() < time) {}
}

void draw(){
  background(0);

  /*** DRAWING: CLIPPING MASKS ***/ 
  leftClips[leftClipIndex].drawClippingMask();
  rightClips[rightClipIndex].drawClippingMask();
  
  
    /*** DRAWING: KEYSTONE FOR FACE TEXTURES ***/ 
    for(int i=0; i<face.length; i++){
    faceTextures[i].beginDraw();
    faceTextures[i].background(0);
    faceTextures[i].image(shade[i], 0, 0, faceTextures[i].width, faceTextures[i].height);
    faceTextures[i].endDraw();
    face[i].render(faceTextures[i]);
  }
  
  
  if(calibrate){
    fill(255, 0, 0);
    text("mapping the " + mappingSide + " human robot face", 20, 30);
    fill(200);
    text("Q = LEFT Side", 20, 70);
    text("W = RIGHT Side", 20, 110);
    text("B = Black Masks", 20, 150);

  }
  else{
    noFill();  
  }
}

void changeMovieRight(int ind) {
  rightClipIndex = ind;
  println ("movie Right changed");
}

void changeMovieLeft(int ind) {
  leftClipIndex = ind;
  println ("movie Left changed");
}


ClippingMask currentClip;

void mousePressed(){  
  if(calibrate){
    // Look to see if the click is inside the shape
    boolean addNewPoint = true;
    for(int i=0;i<currentClip.controlPoints.size();i++){
      if(currentClip.controlPoints.get(i).mouseInside){
        addNewPoint = false;
        break;
      }
    }
    
    // If the click is outside of the shape, add a new control point
    if(addNewPoint){
      currentClip.addPointToShape(mouseX, mouseY, random(0,1));
    }
  }
}

void mouseDragged(){
  if(calibrate){ 
    for(int i=0;i<currentClip.controlPoints.size();i++){
      if(currentClip.controlPoints.get(i).mouseInside){
        currentClip.controlPoints.get(i).updatePoint(currentClip, mouseX, mouseY);
      }
    }
  }
}

void keyPressed(){
  if(key == 'c'){
    calibrate = !calibrate;
    currentClip = leftClips[leftClipIndex];
  }
  else if (key == 'q') { // Map the left side Clipping Mask
    currentClip = leftClips[leftClipIndex];
    mappingSide = "LEFT";
  }
  else if (key == 'w') { // Map the right side Clipping Mask
    currentClip = rightClips[rightClipIndex];
    mappingSide = "RIGHT";
  }
  else if(key == 's'){ // Save the Cliping mask and the Black Mask Keystone maps
    saveClippingMaskCalibration();
    ks.save("mapping.xml");
  }
  else if(key == 'l'){ // Load both Clipping mask and the Black Masks
    loadClippingMaskCalibration();
    ks.load("mapping.xml");
  }
  else if(key == 'b'){ // Map the Black Masks
    calibrate = false;
    ks.toggleCalibration();
  }
  
}

void saveClippingMaskCalibration() {  
  leftClips[leftClipIndex].saveData();
  rightClips[rightClipIndex].saveData();
}

void loadClippingMaskCalibration() {
 
  for (int i = 0; i < leftMovieFilenames.length; i++) {
    leftClips[i].loadData();
  }

  for (int i = 0; i < rightMovieFilenames.length; i++) {
    rightClips[i].loadData();
  }
  
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  
  String message = theOscMessage.addrPattern();
  String[] splitMessage = message.split("/");
  String touchOscKey = splitMessage[2];
  println(touchOscKey);
  
  
  /* LOADING IMAGES AND MOVIES   */
  pushCount++;
  if (pushCount == 1) {
    
    if (touchOscKey.equals("push1")) {
      changeMovieRight(0);
      kick.trigger();
       
    } else if (touchOscKey.equals("push2")) { 
      changeMovieRight(1);
      snare.trigger();
      
    } else if (touchOscKey.equals("push3")) {
      changeMovieLeft(0);
      kick.trigger();
      
    } else if (touchOscKey.equals("push4")) {
      changeMovieLeft(1);
      snare.trigger();
      
    }

  } else {
    pushCount = 0;
  }

}
