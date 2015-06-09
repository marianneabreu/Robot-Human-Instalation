import quickhull3d.*;
import ComputationalGeometry.*;
import processing.video.*;

/*** MAPPING THE BLACK MASKS***/
import deadpixel.keystone.*;
Keystone ks;


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


/***~***/
/***~***/

int currShape = 0;
int numShapes = 2;

/*** CLIPPING MASK FOR BACKGROUND ***/
ClippingMask[] clip = new ClippingMask[numShapes];
boolean calibrate = true;


/*** KEYSTONE FOR FACE TEXTURES ***/
CornerPinSurface[] face = new CornerPinSurface[3];
PGraphics[] faceTextures = new PGraphics[3];
PImage[] shade = new PImage[3];




void setup(){
  size(1024,800,P3D);
  
  /*** SETUP: KEYSTONE FOR FACE TEXTURES ***/
  ks = new Keystone(this);
 
 for(int i=0; i<face.length; i++){
    face[i]= ks.createCornerPinSurface(200,50,20);
    faceTextures[i] = createGraphics(200, 50, P2D);
    shade[0] = loadImage("blackmask.png");
    shade[1] = loadImage("blackmask.png");
    shade[2] = loadImage("blackmask.png");
  }
 
 /*** SETUP: CLIPPING MASK FOR BACKGROUND ***/
  clip[0] =  new ClippingMask(this, "testgreen.mov", "clip0.json", 0);
  clip[1] = new ClippingMask(this, "testblue.mov", "clip1.json", 1);
  
  smooth();
 
  textSize(18);
  
  
   /***TOUCH OSC SETUP***/ 
  frameRate(25);
  oscP5 = new OscP5(this,12000);
  myRemoteLocation = new NetAddress("192.168.1.139",12000);
  
  
   /***SOUND SETUP***/ 
  minim = new Minim(this);  // fills the variable minim with a new object Minim
  kick = minim.loadSample("BD.mp3", 512);  // note: 512 is the buffer rate and should not be changed
  snare = minim.loadSample("SD.wav", 512);


}

void movieEvent(Movie m) {
  m.read();
}

void draw(){
  background(0);
  
  /*** DRAWING: CLIPPING MASK FOR BACKGROUND ***/  
  for(int i=0;i<clip.length;i++){
    clip[i].drawClippingMask();
  }
  
  
    /*** DRAWING: KEYSTONE FOR FACE TEXTURES ***/ 
   for(int i=0; i<face.length; i++){
    faceTextures[i].beginDraw();
    faceTextures[i].background(0);
    faceTextures[i].image(shade[i], 0, 0, faceTextures[i].width, faceTextures[i].height);
    faceTextures[i].endDraw();
    face[i].render(faceTextures[i]);
  }
  
  
  if(calibrate){
    fill(255);
    text("currentShape = " + currShape, 20, 30);
  }
  else{
    noFill();  
  }
}

// Function created to change the images
//void changeImage(String newImageFileName) {
//  shade = loadImage(newImageFileName);
//  println ("image changed"); 
//}

// Function created to change the movies
void changeMovieRight(String newMovieFileName) {
  saveCalibration();
  clip[0] = new ClippingMask(this, newMovieFileName, "clip0.json", 0);
  loadCalibration();
  println ("movie Right changed");
  }


void changeMovieLeft(String newMovieFileName) {
  saveCalibration();
  clip[1] = new ClippingMask(this, newMovieFileName, "clip1.json", 0);
  loadCalibration();
  println ("movie Left changed");
}

void mousePressed(){
    
  if(calibrate){
    ClippingMask currentClip = clip[currShape]; //if you want to interact with another shape, change it here!
    
    boolean addNewPoint = true;
    for(int i=0;i<currentClip.controlPoints.size();i++){
      if(currentClip.controlPoints.get(i).mouseInside){
        addNewPoint = false;
        break;
      }
    }
    if(addNewPoint){
      currentClip.addPointToShape(mouseX, mouseY, random(0,1));
    }
  }
}

void mouseDragged(){
  if(calibrate){
    ClippingMask currentClip = clip[currShape]; //if you want to interact with another shape, change it here!
    
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
  }
  else if(key == 's'){
    saveCalibration();
    ks.save("mapping.xml");
  }
  else if(key == 'l'){
    loadCalibration();
    ks.load("mapping.xml");
  }
  else if(key == 'f'){
    ks.toggleCalibration();
  }
  else if(keyCode == UP){
    currShape++;
  
    if(currShape >= numShapes){
      currShape--;
    }
    else if(currShape < 0){
      currShape = 0;  
    }
  }
  else if(keyCode == DOWN){
    currShape--;
    
    if(currShape >= numShapes){
      currShape--;
    }
    else if(currShape < 0){
      currShape = 0;  
    } 
  }
   
}

void saveCalibration(){
  for(int i=0;i<clip.length;i++){
    clip[i].saveData();
  }
}

void loadCalibration(){
  for(int i=0;i<clip.length;i++){
    clip[i].loadData();
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
  if(touchOscKey.equals("push1")){
    println(pushCount);
    pushCount++;
    println(pushCount);
    if (pushCount == 1) {
   changeMovieRight("testred.mov");
    kick.trigger();
    println("Sound1 played");
    }
    if (pushCount == 2) {
           println(pushCount);
      pushCount = 0;
           println(pushCount);
    }
  } 
  
  
   else if(touchOscKey.equals("push2")){
     pushCount++;
    if (pushCount == 1) {
   changeMovieRight("testyellow.mov");
   snare.trigger();
       println("Sound2 played");
    }
    if (pushCount == 2) {
      pushCount = 0;
    }
  }
  
  
   else if(touchOscKey.equals("push3")){
      pushCount++;
    if (pushCount == 1) {
   changeMovieRight("testgreen.mov");
   kick.trigger();
       println("Sound3 played");
    }
    if (pushCount == 2) {
      pushCount = 0;
  }
   }
  
   else if(touchOscKey.equals("push4")){
      pushCount++;
    if (pushCount == 1) {
   changeMovieRight("testred.mov");
   snare.trigger();
       println("Sound4 played");
    }
    if (pushCount == 2) {
      pushCount = 0;
  }
}

  
   else if(touchOscKey.equals("push5")){
      pushCount++;
    if (pushCount == 1) {
   changeMovieLeft("testred.mov");
   snare.trigger();
       println("Sound4 played");
    }
    if (pushCount == 2) {
      pushCount = 0;
  }
}

  
   else if(touchOscKey.equals("push6")){
      pushCount++;
    if (pushCount == 1) {
         snare.trigger();
   changeMovieLeft("testyellow.mov");

       println("Sound4 played");
    }
    if (pushCount == 2) {
      pushCount = 0;
  }
}

  
   else if(touchOscKey.equals("push7")){
      pushCount++;
    if (pushCount == 1) {
         snare.trigger();
   changeMovieLeft("testyellow.mov");
   snare.trigger();
       println("Sound4 played");
    }
    if (pushCount == 2) {
      pushCount = 0;
  }
}

  
   else if(touchOscKey.equals("push8")){
      pushCount++;
    if (pushCount == 1) {
         snare.trigger();
   changeMovieLeft("testyellow.mov");

       println("Sound4 played");
    }
    if (pushCount == 2) {
      pushCount = 0;
  }
}


}
