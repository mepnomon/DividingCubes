import com.dhchoi.*;
//------------------------------------------
// ICP - 3036: Computer Graphics 3
// Assignment 4: Dividing Cubes Visualization
// @author: Dorian Dressler (eeu436)
// @version: Version 1.1
// @Updated: 2017-02-28
//------------------------------------------
PFont f;
//timer values
long finish = 6000, interval = 1200;//fmr 50
CountdownTimer timer = CountdownTimerService.getNewCountdownTimer
  (this).configure(interval, finish);

//offsets
final float POS_Y_OFFSET = 150, POS_X_OFFSET = 100, BOX_SIZE = 100;
float Y_MAX = POS_Y_OFFSET + (BOX_SIZE*4);
float X_MAX = POS_X_OFFSET + (BOX_SIZE*4); //*3
float y_intercepts[] = {POS_X_OFFSET, POS_X_OFFSET+BOX_SIZE, POS_X_OFFSET+(BOX_SIZE*2), POS_X_OFFSET+(BOX_SIZE*3)};
float x_intercepts[] = {POS_Y_OFFSET, POS_Y_OFFSET+BOX_SIZE, POS_Y_OFFSET+(BOX_SIZE*2), POS_Y_OFFSET+(BOX_SIZE*3)};
int fieldNumbers[] = {1, 1, 1, 1, 1, 6, 4, 4, 4, 1, 2, 7, 9, 5, 3, 3, 6, 6, 5, 3, 1, 2, 3, 4, 3};
int pxSize =10; //pixel size, used for drawing cubes
int size = 5; // other size value


//slider position
float s_xpos, s_ypos;
float x_speed = 2;
//slider control
boolean sliderCrossed = false;
boolean timerSet = false;
boolean timerRunning = false;
boolean timerStarted = false;
boolean stopSlider = false;
boolean resetSlider = false; //slider back to base position?
boolean intervalPulse = false;
int sliderLocation = 0;

//mechanics, colors, etc...

//control variables
int divisionStep; //count division steps
long updatedCountdown; // used when slider should move faster
int boxVisited = 0; //how many boxes the slider visited, incrmenets after final sub-division step
final int MAX_BOXES_VISITED = 12; //the max number of boxes the slider has to visist
int edgeColors[] = {2, 3, 3, 5, 1, 6, 6, 1, 0, 3, 3, 4}; //order in which edge colors are sleected
boolean maskOn[] = new boolean[10]; //contains booleans that control the mask
int contourIs = 10;
color col[] = new color[contourIs]; //contains individual colors for contour line blocks
color colOff = color(128, 128, 128); //color off
color colOn = color(255, 0, 0);     //color on
boolean subdivide = false;         //subdivide cuberille?
final int MASK_DEFAULT = 0;
int maskType = MASK_DEFAULT;
int tempMaskType = 0;
color colorForMask;
int colorIterator = -1;
int divisionType = 0; //controls division <---- reset to 0
int divisionCount = 0;
//incr somewhere
float lastX = 0, lastY = 0;

//text
String displayedText;
String defaultText = "No intersection";
String intersected = "Contour intersects";
String dividing = "Dividing cuberille";
String subDividing = "while(cube > pixel size)\ndo>>subdivision";
String shading = "cube == pixel size\ndo>>'Phong Shading'";
String eventText = defaultText;

int frameWidth = 600;
int frameHeight = 700;

//set up animation
void setup() {
  frameRate(60); //set frame rate
  background(255); //set background
  size(600, 700); //set frame size
  f = createFont("Arial", 12, true); //set text size
  s_xpos = POS_X_OFFSET; //start slider x
  s_ypos = POS_Y_OFFSET;//start slider y
  //populate colors
  for (int i = 0; i < col.length; i++) {
    col[i] = colOff;
  }
  //stop for video recording
 //delay(10000);
}

void draw() {
;
  if (!stopSlider) { //slider is moving

    clear(); //clear
    background(255); //set background
    drawContour();//draw pixel cloud
    drawGrid();//draw grid
    slider(s_xpos, s_ypos);// draw slider 
    moveSlider(); //move slider
    sliderFinishTest(); //tests if slider has reached end
    sliderEdgeTest(); //tests if slider exceeds edge
    displayOtherInfo();
  }

  //slider is stopped
  //subdivision animation starts
  else { //if stop slider is true
    //drawContour();
    //if in this state and timer has not started
    timerTest();
    //activate timer
    //start timer when first time slider halted
    if (sliderCrossed) {
      sliderCrossed = false; //reset
      print("\nbox visited" + boxVisited);
      //drawContour();
      drawIntersectingLines(s_xpos, s_ypos, edgeColors[boxVisited]);
    }

    //show subdivision animation
    if (intervalPulse && subdivide) { //when an interval occurs
      divideCube(s_xpos, s_ypos, 0);
      intervalPulse = false;
      print("\ndiv type " +divisionType);
      //show subdivision
      print("\nDiv count" + divisionCount);
      if (divisionCount == 1) { //change event text
        eventText = dividing ;
      }
      if (divisionCount == 2) { //change evnet text
        eventText = subDividing;
      }
      if (divisionCount == 3) { //if last division
        //lerpContour();
        ++tempMaskType;
        selectDivisionType(); 
        maskType = tempMaskType;
        ++divisionType;
        eventText = subDividing;
      }
      drawIntersectingLines(s_xpos, s_ypos, edgeColors[boxVisited]);
    }
    slider(s_xpos, s_ypos);
    if (boxVisited == 5 || boxVisited == 6) {
      eventText = defaultText;
      finish = 2000;
    } else {
      finish = 5000;
    }

    textBubble(s_xpos, s_ypos);
    displayOtherInfo();
  }//end if
  if (boxVisited == MAX_BOXES_VISITED) {
    background(255);
    drawContour();
    stroke(colOff);
    text("Resulting Pixel Cloud", frameWidth*3, frameHeight*.75);
  }
}//end draw

//adds text and author
PShape displayOtherInfo() {
  PShape textShape = createShape();
  String layer = "Slice: 3";
  String contourSelected = "Contour Selected: 5";
  String author = "Dorian Dressler, Bangor University 2017";
  String title = "Dividing Cubes Explanatory Visualization";
  beginShape();
  //stroke(0);
  noStroke();
  strokeWeight(3);
  textSize(15);
  text(title, frameWidth*0.25, frameHeight*0.05);
  textSize(12);
  text(contourSelected, POS_X_OFFSET+(BOX_SIZE*2.8), POS_Y_OFFSET+(BOX_SIZE*4.2));
  text(layer, POS_X_OFFSET+(BOX_SIZE*.1), POS_Y_OFFSET+(BOX_SIZE*4.2));
  text(author, frameWidth*0.05, frameHeight*0.95);
  endShape();
  return textShape;
}

//selects division animation
void selectDivisionType() {
  if (divisionType == 0) { //show corner left
    divisionTopLeft(s_xpos, s_ypos);
  } else if (divisionType == 4) { //divide left //make this an interval control variable
    divisionLeft(s_xpos, s_ypos);
  } else if (divisionType == 3 || divisionType == 5) {
    divisionRight(s_xpos, s_ypos);
  } else if (divisionType == 6) {
    divisionBL(s_xpos, s_ypos);
  } else if (divisionType == 9) {
    divisionBR(s_xpos, s_ypos);
  } else {
    division(s_xpos, s_ypos);
  }
}

//tests if timer has started, activates timer if not
void timerTest() {
  if (!timerStarted) {
    print("\ntimer started!!!!");
    //start timer
    timer.start();
    eventText = intersected;
    //change notify
    timerStarted = true;
  }
}

//tests if slider is out of bounds
void sliderEdgeTest() {
  if (s_ypos > POS_Y_OFFSET && s_xpos >= y_intercepts[sliderLocation] && !resetSlider) {

    if (!sliderCrossed) { //if slider is not changing rows
      stopSlider = true; //halt the slider
      sliderCrossed = true;
    }
  }//end if
}

//tests if animation is finished, slider = end
void sliderFinishTest() {
  //change rows if slider out of bounds
  if (s_xpos >= X_MAX-64) {

    //y incremented
    s_ypos = s_ypos + BOX_SIZE;//y
    //reset x
    s_xpos = POS_X_OFFSET;

    //refresh background  
    background(255);
    //draw grid
    drawGrid();
    //draw slider
    slider(s_xpos, s_ypos);
    //reset slider is false
    resetSlider = false;
  }
}

//division animation
PShape division(float x, float y) {
  PShape divide = createShape();
  ++colorIterator;
  //drawcontourI(); //redraw contourI
  float x1 = x;
  float y1 = y;
  float default_vert_divider = y+((float)BOX_SIZE/4)-size;
  float vertDivider = default_vert_divider;

  beginShape();
  stroke(0);
  strokeWeight(1);
  //center divider
  line(x+(BOX_SIZE/4)+size, y, x+(BOX_SIZE/4)+size, vertDivider);

  //criss cross center
  for (int i = 0; i < 10; i++) {
    //vertical
    if (i == 2 || i == 7) { //<---- work this out
      vertDivider =  y+((float)BOX_SIZE/2);
    } else {
      vertDivider = default_vert_divider;
    }
    //horizontal
    line(x, y, x, vertDivider);
    line(x1, y1, x1+BOX_SIZE, y1);
    x+=pxSize; 
    if (i < 2) {
      y1+=pxSize;
    }
    if (i==2) {
      y1+=pxSize;
    }
  }
  endShape();
  return divide;
}

//moves the slider
void moveSlider() {
  if (boxVisited < MAX_BOXES_VISITED) {
    s_xpos = s_xpos + (x_speed*1);//ove slider
  }
}

//with each timer tick
void onTickEvent(CountdownTimer t, long timeLeftUntilFinish) {

  print("\ninterval");
  intervalPulse = true; //interval pulse controls drawing
  ++divisionCount; //one more division has occurred
  //colorForMask = lerp(colOff, colOn, .100);
}

//when timer has finished
void onFinishEvent(CountdownTimer t) {

  col[colorIterator] = colOn;//need another control var
  print("sLoc: " + sliderLocation);
  timerStarted = false; //reset timer
  divisionCount = 0; //reset division count
  if (sliderLocation > 2) { //if sliderLocation exceeds this
    print("\nWAAAAH");
    sliderLocation = 0; //reset this
    resetSlider = true; //slider has been reset
  } else {
    ++sliderLocation;
  }
  ++boxVisited;
  stopSlider = false;
  maskType = MASK_DEFAULT;
  eventText = defaultText;
}

//sider
PShape slider(float x, float y) {
  //-----------------    
  //print("\nslider x: " +x+ "y:"+y);
  final int VAL_SPACE = 15;
  PShape slider = createShape();
  beginShape();
  fill(255, 0); //translucent
  stroke(0);
  strokeWeight(1.5);
  rect(x, y, BOX_SIZE, BOX_SIZE);
  rect(x-VAL_SPACE, y-VAL_SPACE, VAL_SPACE, VAL_SPACE);
  rect(x-VAL_SPACE, y+BOX_SIZE, VAL_SPACE, VAL_SPACE);
  rect(x+BOX_SIZE, y-VAL_SPACE, VAL_SPACE, VAL_SPACE);
  rect(x+BOX_SIZE, y+BOX_SIZE, VAL_SPACE, VAL_SPACE);

  //outer lines, frame color
  //left side
  line(x-size, y, x-size, y+BOX_SIZE);
  //up
  line(x, y-size, x+BOX_SIZE, y-size); 
  //right
  line(x+BOX_SIZE+size, y, x+BOX_SIZE+size, y+BOX_SIZE); 
  //down
  line(x, y+(BOX_SIZE+size), x+BOX_SIZE, y+(BOX_SIZE+size));
  strokeWeight(1);
  //draw the intersecting line, always on, faster than testing intersects
  line(y_intercepts[0], y, y_intercepts[0], y+BOX_SIZE);
  line(y_intercepts[1], y, y_intercepts[1], y+BOX_SIZE);
  line(y_intercepts[2], y, y_intercepts[2], y+BOX_SIZE);
  endShape();
  //drawIntersectingLines(x,y,null);
  //show text bubble
  textBubble(x, y);
  return slider;
}

//selects appropriate colors for intersection type
void drawIntersectingLines(float x, float y, int type) {
  color cols[] = new color[4];
  color red = color(255, 0, 0);
  color gr = color(0, 100, 0);
  color k = color(0, 0, 0);
  //initial color condition
  cols[0]= k; 
  cols[1] = k; 
  cols[2] = k; 
  cols[3] = k; 


  drawContour();
  subdivide = true;
  //define colors of intersection markers
  switch(type) {
  case 0: 
    cols[0]= red; 
    cols[1] = gr; 
    cols[2] = gr; 
    cols[3] = red; 
    break; 
  case 1: 
    cols[0]= red; 
    cols[1] = gr; 
    cols[2] = red;
    cols[3] = gr; 
    break;
  case 2: 
    cols[0]= red; 
    cols[1] = red;
    cols[2] = gr; 
    cols[3] = gr; 
    break;
  case 3: 
    cols[0]= gr; 
    cols[1] = red; 
    cols[2] = gr; 
    cols[3] = red; 
    break;
  case 4: 
    cols[0]= gr; 
    cols[1] = gr; 
    cols[2] = red; 
    cols[3] = red; 
    break;
  case 5: 
    cols[0]= gr; 
    cols[1] = red; 
    cols[2] = red; 
    cols[3] = gr; 
    break;
  case 6: 
    subdivide = false;
    break;
  }
  //draw intersection markers
  float offset = 2.05;
  //draw markers
  beginShape();
  strokeWeight(3.5);
  //left
  stroke(cols[0]);
  line(x-offset, y, x-offset, y+BOX_SIZE);
  //top
  stroke(cols[1]);
  line(x, y-offset, x+BOX_SIZE, y-offset);
  //right
  stroke(cols[2]);
  line(x+(BOX_SIZE+offset), y, x+(BOX_SIZE+offset), y+BOX_SIZE);
  //down
  stroke(cols[3]);
  line(x, y+(BOX_SIZE+offset), x+BOX_SIZE, y+(BOX_SIZE+offset));
  endShape();
  strokeWeight(1);
  stroke(0);
}

//divides cube in 2
void drawCenterDivider(float x, float y) {
  drawContour();
  beginShape();
  stroke(0);
  strokeWeight(1);
  line(x+(BOX_SIZE/2), y, x+(BOX_SIZE/2), y+BOX_SIZE);
  line(x, y+(BOX_SIZE/2), x+BOX_SIZE, y+(BOX_SIZE/2));
  endShape();
}

void divideCube(float x, float y, int type) {

  //if 0 type is main cross division only
  drawContour();
  switch(type) {
  case 0: 
    drawCenterDivider(x, y); 
    break;
  case 1: 
    drawCenterDivider(x, y); 
    break;
  }
  slider(x, y);
}

//shape for division top left
PShape divisionTopLeft(float x, float y) {
  PShape divider = createShape();
  ++colorIterator;
  //drawContour(); //redraw contourI
  float x1 =  x+(BOX_SIZE/2);
  float y1 = y;
  beginShape();
  stroke(0);
  strokeWeight(1);
  //criss cross center
  for (int i = 0; i < 10; i++) {

    if (i < 4) {
      //horizontal
      line(x+(BOX_SIZE/2), y, x+BOX_SIZE, y);
      if (i < 3) {
        line(x1, y1, x1, y1+(BOX_SIZE));
      } else {
        line(x+(BOX_SIZE/2), y, x+BOX_SIZE, y);
        line(x1, y1, x1, y1+(BOX_SIZE/2));
      }
    } else {
      line(x+(BOX_SIZE/2), y, x+((BOX_SIZE/2)+(pxSize*2)), y);
    }
    //vertical
    y+=pxSize;
    if (i < 5) {
      x1+=pxSize;
    }
  }
  endShape();
  return divider;
} 
//bottom left division
PShape divisionBL(float x, float y) {
  PShape divider = createShape();
  ++colorIterator;
  beginShape();
  stroke(0);
  strokeWeight(1);
  //center divider
  //vertical
  line(x+((BOX_SIZE)-(BOX_SIZE*.25)), y, x+((BOX_SIZE)-(BOX_SIZE*.25)), y+((BOX_SIZE/2)));
  //horizontal
  line(x+(BOX_SIZE/2), y+(BOX_SIZE/4), x+BOX_SIZE, y+(BOX_SIZE/4));
  endShape();
  return divider;
}

//bottom right division
PShape divisionBR(float x, float y) {
  PShape divider = createShape();
  ++colorIterator;
  beginShape();
  stroke(0);
  strokeWeight(1);
  //vertical
  line(x+(BOX_SIZE/4), y, x+(BOX_SIZE/4), y+(BOX_SIZE/2));
  //horizontal
  line(x, y+(BOX_SIZE/4), x+(BOX_SIZE/2), y+(BOX_SIZE/4));
  endShape();
  return divider;
}

//left side division
PShape divisionLeft(float x, float y) {
  PShape divider = createShape();
  int across = 4;
  ++colorIterator; //increase color value
  beginShape();
  stroke(0);
  strokeWeight(1);
  //horizontal subdiv
  line(x+(BOX_SIZE/2), y+(BOX_SIZE/4), x+BOX_SIZE, y+(BOX_SIZE/4));
  //horizontal subdiv below
  line(x+(BOX_SIZE/2), y+((BOX_SIZE)-(BOX_SIZE*.25)), x+BOX_SIZE, y+((BOX_SIZE)-(BOX_SIZE*.25)));
  //vertical subdiv
  line(x+((BOX_SIZE)-(BOX_SIZE*.25)), y, x+((BOX_SIZE)-(BOX_SIZE*.25)), y+BOX_SIZE);


  //draw shorter subdividers
  pushMatrix();
  for (int i = 0; i < across; i++) {
    line(x+(BOX_SIZE/2), y+(BOX_SIZE/8), x+((BOX_SIZE)-(BOX_SIZE*.25)), y+(BOX_SIZE/8));
    translate(0, BOX_SIZE/4);
  }
  popMatrix();
  endShape();
  return divider;
}

//divides right side
PShape divisionRight(float x, float y) {
  PShape divide = createShape();
  ++colorIterator;
  //drawContour(); //redraw contourI
  //float x1 = x;
  //float x2 = x;
  //float y1 = y;
  //float default_vert_divider = y+((float)BOX_SIZE/4)-size;
  //float vertDivider = default_vert_divider;

  beginShape();
  stroke(0);
  strokeWeight(1);
  //center divider
  //line(x+(BOX_SIZE/4)+size,y,x+(BOX_SIZE/4)+size, vertDivider);

  //draw vertical half drivider
  line(x+(BOX_SIZE/4), y, x+(BOX_SIZE/4), y+BOX_SIZE);

  //horizontal half divider 1
  line(x, y+(BOX_SIZE/8), x+(BOX_SIZE/4), y+(BOX_SIZE/8));
  //horizontal half divider 2
  line(x, y+(BOX_SIZE/4), x+(BOX_SIZE/4), y+(BOX_SIZE/4));

  //bototm half divider
  line(x, y+(BOX_SIZE-(BOX_SIZE*.25)), x+(BOX_SIZE/4), y+(BOX_SIZE-(BOX_SIZE*.25)));
  //some other divider
  line(x+(BOX_SIZE/8), y, x+(BOX_SIZE/8), y+(BOX_SIZE));
  endShape();
  return divide;
}


//draws pixel cloud
void drawContour() { //timer needs to control mask type
  //int size = 5;
  int cols = int(BOX_SIZE/pxSize);
  int lineWidth = 1;
  //top left 1
  contourTL(POS_X_OFFSET+((BOX_SIZE/2)+pxSize), POS_Y_OFFSET+BOX_SIZE+pxSize, col[0]);
  //top 1
  contour(POS_X_OFFSET+BOX_SIZE, POS_Y_OFFSET+BOX_SIZE+pxSize, 100, 10, col[1]);
  //top 2
  contour(POS_X_OFFSET+BOX_SIZE*2, POS_Y_OFFSET+BOX_SIZE+pxSize, 100, 10, col[2]);
  //top right
  //contourI(POS_X_OFFSET+(BOX_SIZE*3), POS_Y_OFFSET+BOX_SIZE, 10, lineWidth,col[3]);
  contour(POS_X_OFFSET+(BOX_SIZE*3), POS_Y_OFFSET+BOX_SIZE+pxSize, 10, 90, col[3]);
  //center left
  contour(POS_X_OFFSET+((BOX_SIZE/2)+pxSize), POS_Y_OFFSET+(BOX_SIZE*2), 10, 100, col[4]);
  //center right
  contour((POS_X_OFFSET+(BOX_SIZE*3)), POS_Y_OFFSET+(BOX_SIZE*2), 10, 100, col[5]);
  //bottom left
  contourBL(POS_X_OFFSET+((BOX_SIZE/2)+pxSize), POS_Y_OFFSET+(BOX_SIZE*3), col[6]);
  //bottom 1
  contour(POS_X_OFFSET+BOX_SIZE, POS_Y_OFFSET+(BOX_SIZE*3)+pxSize, 100, 10, col[7]);
  //bottom 2
  contour(POS_X_OFFSET+BOX_SIZE*2, POS_Y_OFFSET+(BOX_SIZE*3)+pxSize, 100, 10, col[8]);
  //bottom right
  contour(POS_X_OFFSET+((BOX_SIZE*3)), POS_Y_OFFSET+(BOX_SIZE*3), 10, 20, col[9]);

  //chooses with mask to display on top of the contour, when subdivision step is last
  print("\nMaskType:" + maskType);
  switch(maskType) {
  case 0: 
    break; //default no contourI
  case 1:
    contourTopLeftMask(POS_X_OFFSET+((BOX_SIZE/2)+pxSize), POS_Y_OFFSET+BOX_SIZE+size, 9, 4); 
    break;
  case 2:
    contourMask(POS_X_OFFSET+BOX_SIZE, POS_Y_OFFSET+BOX_SIZE+size, lineWidth, cols); 
    break;
  case 3: 
    contourMask(POS_X_OFFSET+BOX_SIZE*2, POS_Y_OFFSET+BOX_SIZE+size, lineWidth, cols); 
    break;
  case 4: 
    contourMask(POS_X_OFFSET+(BOX_SIZE*3), POS_Y_OFFSET+BOX_SIZE+size, 9, lineWidth); 
    break;
  case 5: 
    contourMask(POS_X_OFFSET+((BOX_SIZE/2)+pxSize), POS_Y_OFFSET+(BOX_SIZE*2)-size, cols, lineWidth); 
    break;
  case 6: 
    contourMask(POS_X_OFFSET+((BOX_SIZE*3)), POS_Y_OFFSET+(BOX_SIZE*2)-size, cols, lineWidth); 
    break;
  case 7: 
    contourBLMask(POS_X_OFFSET+((BOX_SIZE/2)+pxSize), POS_Y_OFFSET+(BOX_SIZE*3)-size);
    break;
  case 8: 
    contourMask(POS_X_OFFSET+BOX_SIZE, POS_Y_OFFSET+(BOX_SIZE*3)+size, lineWidth, cols); 
    break;
  case 9: 
    contourMask(POS_X_OFFSET+BOX_SIZE*2, POS_Y_OFFSET+(BOX_SIZE*3)+size, lineWidth, cols);
    break;
  case 10:
    contourMaskBR(POS_X_OFFSET+((BOX_SIZE*3)), POS_Y_OFFSET+(BOX_SIZE*3)-size); 
    break;
  }
}

//bottom left contour
PShape contourBL(float x, float y, color shapeColor) {
  PShape contour = createShape();
  beginShape();
  noStroke();
  fill(shapeColor);
  rect(x, y, 10, 20);
  rect(x+10, y+10, 30, 10);
  endShape();
  strokeWeight(1);
  stroke(1);
  endShape();
  return contour;
}

//bottom right contour
PShape contourMaskBR(float x, float y) {
  eventText = shading;
  PShape mask = createShape();
  beginShape();
  pushMatrix();
  fill(colOff);
  for (int i = 0; i < 4; i++) {
    //left row
    rect(x, y+size, size, size);
    //right row
    rect(x+size, y+size, size, size);
    translate(0, size);
  }
  popMatrix();
  return mask;
}

//bottom left contour mask
PShape contourBLMask(float x, float y) {
  eventText = shading;
  PShape mask = createShape();
  float y1 = y+(size*4)-size;
  beginShape();
  pushMatrix();
  fill(colOff);
  for (int i  = 0; i < 4; i++) {
    //left row
    rect(x, y+size, size, size);
    //right row
    rect(x+size, y+size, size, size);
    //y1 = y + size; 
    translate(0, size);
  }
  popMatrix();
  pushMatrix();
  for (int i = 0; i < 8; i++) {
    rect(x, y1, size, size);
    rect(x, y1+size, size, size);
    translate(size, 0);
  }
  popMatrix();
  endShape();

  return mask;
}

//primary contour
PShape contour(float x, float y, float height, float width, color shapeColor) {
  PShape contour = createShape();
  beginShape();
  noStroke();
  fill(shapeColor);
  //fill(lerpColor(colOff,colOn, (millis()%5000)/5000.0));
  rect(x, y, height, width);
  endShape();
  //reset values
  strokeWeight(1);
  stroke(1);
  endShape();
  return contour;
}

//top left contour
PShape contourTL(float x, float y, color shapeColor) {
  //eventText = shading;
  PShape contour = createShape();
  noStroke();
  beginShape();
  fill(shapeColor);
  //fill(lerpColor(colOff,colOn, (millis()%5000)/5000.0));
  rect(x, y, 40, 10, 2);
  rect(x, y, 10, 90, 2);
  //color(shapeColor);
  strokeWeight(1);
  stroke(1);
  endShape();
  return contour;
}

PShape contourTopLeftMask(float x, float y, int rows, int cols) {
  eventText = shading;
  PShape mask = createShape();
  //fill(colOn,1);
  color(0);
  stroke(1);
  beginShape();
  color(255);
  stroke(1);
  pushMatrix();
  float size = (float)(pxSize/2);
  //drow horizontal
  for (int i=0; i < cols*2; i++) { //combine lerps
    rect(x, y+size, size, size);
    rect(x, y+size*2, size, size);
    translate(size, 0);
  }
  popMatrix();

  pushMatrix();
  for (int i = 0; i < rows*2; i++) {
    //fill(lerpColor(colOff,colOn, (millis()%5000)/5000.0));
    //left row
    rect(x, y+size, size, size);
    //right row
    rect(x+size, y+size, size, size);
    translate(0, size);
  }
  popMatrix();
  endShape();
  return mask;
}

//main contour mask
PShape contourMask(float x, float y, int rows, int cols) { // <------------ HERE
  eventText = shading;
  PShape mask = createShape();
  beginShape();
  pushMatrix();
  float size = (float)(pxSize/2);
  for (int i = 1; i <= cols*2; i++) {
    //fill(lerpColor(colOff, colOn, (millis()%5000)/5000.0));
    for (int j = 1; j <= rows*2; j++) {
      rect(x, y+size*j, size, size);
    }
    translate(size, 0);
  }
  popMatrix();
  endShape();
  return mask;
}

//text bubble displayed underneath slider
PShape textBubble(float x, float y) {
  PShape bubble = createShape();

  float bX = x-(BOX_SIZE*.45); 
  float bY = y+BOX_SIZE+(BOX_SIZE*.25);
  fill(255);
  strokeWeight(2);
  beginShape();
  rect(bX, bY, BOX_SIZE*1.75, BOX_SIZE*.75, 7);
  stroke(1);
  fill(0);
  text(eventText, bX+(BOX_SIZE*.35), bY+BOX_SIZE*.4);

  endShape();
  return bubble;
}
//draws the main grid
//--------------- 
void drawGrid() {
  //---------------
  float pos_x = POS_X_OFFSET;
  float pos_y = POS_Y_OFFSET; //box size
  int grid_l = 4;  //5x5 grid
  beginShape();
  strokeWeight(1);
  //color black
  fill(255, 1);
  //draw grid
  for (int i = 0; i  < grid_l; i++) {
    //set offset
    translate(pos_x, pos_y);

    for (int j = 0; j < grid_l; j++) {
      //draw "pixel"
      //push
      rect(0, 0, BOX_SIZE, BOX_SIZE);
      //move along x-axis
      translate(BOX_SIZE, 0);
    }
    resetMatrix();
    //increase y for offset
    pos_y += BOX_SIZE;
  }

  //setup field values
  fill(0);
  textSize(12);
  //print font
  pos_y = POS_Y_OFFSET;
  pos_x = POS_X_OFFSET - 6;
  int l_count = 0;

  //add field numbers to grid
  for (int i = 0; i < fieldNumbers.length; i++) {
    text(Integer.toString(fieldNumbers[i]), pos_x, pos_y);

    if (l_count != 0 && l_count%grid_l == 0) {
      pos_y += BOX_SIZE;
      pos_x = POS_X_OFFSET-6;
      l_count  = 0 ;
    } else {
      pos_x += (BOX_SIZE);
      ++l_count;
    }
  }
  endShape();
}