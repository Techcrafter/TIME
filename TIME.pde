/*

    This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

*/

/*

                                     .         .                          
8888888 8888888888  8 8888          ,8.       ,8.          8 8888888888   
      8 8888        8 8888         ,888.     ,888.         8 8888         
      8 8888        8 8888        .`8888.   .`8888.        8 8888         
      8 8888        8 8888       ,8.`8888. ,8.`8888.       8 8888         
      8 8888        8 8888      ,8'8.`8888,8^8.`8888.      8 888888888888 
      8 8888        8 8888     ,8' `8.`8888' `8.`8888.     8 8888         
      8 8888        8 8888    ,8'   `8.`88'   `8.`8888.    8 8888         
      8 8888        8 8888   ,8'     `8.`'     `8.`8888.   8 8888         
      8 8888        8 8888  ,8'       `8        `8.`8888.  8 8888         
      8 8888        8 8888 ,8'         `         `8.`8888. 8 888888888888 
      
      Version 1.0 - RELEASE - EN_US
      Developed by Techcrafter in 2022!

*/

import processing.sound.*;  // importing sound library

PImage splash;  // splash image
PImage current;  //currently displayed image in-game

PImage[] mousePointer = new PImage[3];  // different types of mouse pointers in-game (0: default; 1: path; 2: object)
static int mousePointerMinus = 16;  // where to display the mouse pointer image

PImage loadIcon;  // ui icons for loading and saving the game
PImage saveIcon;
PImage updateIcon;
PImage yesIcon;  // prompt icons
PImage noIcon;

SoundFile musicAudio;  // music is stored here

int i;  // general var

static String applicationIdentifier = "TIME-EN_US";  // application identifier for multiple adventures in one game, DLC's, ...
static byte[] version = {1, 0};
static int delayTime = 200;  // delay time between in-game screens

boolean initFrame = true;  // stores if the initial frame gets rendered
static int[] defaults = {127, 127, 0};  // default values
static byte default3 = 0;  // default byte value (default 3 isn't an int)
int mapX;  // current x position on the map
int mapY;  // current y position on the map
int mapSub;  // current sub-screen on the current position
static int saveSlot = 1;
byte[] location = new byte[3];  // location for save game
byte[] inventory = new byte[256];  // inventory (unused in TIME-EN_US:1.0)
byte[][] mapState = new byte[256][256];  // state of each map tile
byte[] mapData = new byte[64];  // objects on the current map tile loaded from .dat file for each tile
int[] mapDataInt = new int[64];  // the above converted to int values
boolean onSelection = false;  // if pointer is currently hovering over a path or object
int prompt = 0;  // stores data for prompting user

static boolean editor = false;  // set to true for editor mode; only meant for development purposes, but is fun anyways; able to destroy the game, so use with caution!
int editorSelection = 0;  // currently setting selected in editor
int editorElement = 0;  // currently selected element in editor
byte[] editorData = new byte[8];  // editor data to be written to .dat file

int creditsFrame = 0;

void setup()
{
  print("TIME - Version 1.0 - RELEASE - EN_US\r\nDeveloped by Techcrafter in 2022!\r\nHave fun! ;)");  // print welcome message
  size(1280, 960);  // define window size
  background(0);  // black background
  
  splash = loadImage("data/graphics/generic/splash.png");  // load and display splash image
  image(splash, 0, 0);
  
  if(editor)  // print and display if in editor mode
  {
    textSize(32);
    fill(255);
    text("EDITOR", 372, 280);
    print("\r\nEDITOR MODE!");
  }
  
  return;
}

void init()  // initialize the game (load various files); gets called once after setup()
{
  for(i = 0; i < 3; i++)
  {
    mousePointer[i] = loadImage("data/graphics/pointers/" + i + ".png");
  }
  
  loadIcon = loadImage("data/graphics/ui/load.png");
  saveIcon = loadImage("data/graphics/ui/save.png");
  updateIcon = loadImage("data/graphics/ui/update.png");
  yesIcon = loadImage("data/graphics/ui/yes.png");
  noIcon = loadImage("data/graphics/ui/no.png");
  
  if(!editor)
  {
    musicAudio = new SoundFile(this, "data/audio/music.wav");
  }
  else
  {
    musicAudio = new SoundFile(this, "data/audio/editor.wav");
  }
  
  delay(5000);  // delay to display splash
  
  mapX = defaults[0];  // setting default values
  mapY = defaults[1];
  mapSub = defaults[2];
  mapState[mapX][mapY] = default3;
  swap();  // swap to the new location
  musicAudio.loop();  // loop the music continously throughout the entire game
  
  return;
}

void draw()  // main loop
{
  if(initFrame)  // run init() funciton on first frame of draw()
  {
    init();
    initFrame = false;
  }
  else if(prompt == 4)
  {
    delay(5000);
    musicAudio.loop();
    prompt = 0;
  }
  else if(prompt > 0)
  {
    
    if(mousePressed && mouseY >= 895)
    {
      if(mouseX < 64)  // yes
      {
        switch(prompt)
        {
          case 1:  // load
            loadGame();
            break;
          
          case 2:  // save
            saveGame();
            break;
          
          case 3:  // update check
            updateCheck();
            break;
        }
        
        if(prompt != 4)
        {
          prompt = 0;
        }
      }
      else if(mouseX >= 1215)  // no
      {
        prompt = 0;
        delay(200);
      }
    }
    
    return;
  }
  else if(mapX == 255 && mapY == 255 && mapSub == 0)
  {
    credits();
    return;
  }
  
  image(current, 0, 0);  // display the current image
  
  if(editor && editorSelection >= 0)  // editor related stuff goes here
  {
    textSize(16);  // display placed objects as rectangles
    for(i = 0; i < 8; i++)
    {
      if(i < 4)
      {
        fill(0, 0, 255);
      }
      else
      {
        fill(255, 0, 0);
      }
      rect(mapDataInt[i * 8] * 5, mapDataInt[i * 8 + 2] * 3.75, mapDataInt[i * 8 + 1] * 5 - mapDataInt[i * 8] * 5, mapDataInt[i * 8 + 3] * 3.75 - mapDataInt[i * 8 + 2] * 3.75);
      fill(255);
      text(i, mapDataInt[i * 8] * 5 + 8, mapDataInt[i * 8 + 2] * 3.75 + 16);
    }
    
    textSize(32);  // display various settings on screen
    fill(0);
    text(mapX + " | " + mapY + " | " + mapSub + " | " + (mapState[mapX][mapY] & 0xFF), 32, 32);
    text(editorSelection + " | " + editorElement, 32, 96);
    text((editorData[4] & 0xFF) + " | " + (editorData[5] & 0xFF) + " | " + (editorData[6] & 0xFF) + " | " + (editorData[7] & 0xFF), 32, 160);
    
    if(editorSelection >= 4)  // place objects mode
    {
      fill(255, 0, 0);  // display editor cursor
      rect(mouseX - 2, mouseY - 2, 4, 4);
      
      if(editorData[0] != 0 || editorData[2] != 0)  // display current object box when placing
      {
        if(mouseX > (editorData[0] & 0xFF) * 5 && mouseY > (editorData[2] & 0xFF) * 3.75)
        {
          fill(0, 255, 0);
        }
        else
        {
          fill(255, 0, 0);
        }
        rect((editorData[0] & 0xFF) * 5, (editorData[2] & 0xFF) * 3.75, mouseX - (editorData[0] & 0xFF) * 5, mouseY - (editorData[2] & 0xFF) * 3.75);
      }
      
      if(mousePressed)  // register mouse clicks
      {
        if(editorData[0] == 0 && editorData[2] == 0)  // set x1 and y1
        {
          editorData[0] = byte(mouseX / 5);
          editorData[2] = byte(mouseY / 3.75);
          print("\r\n 1st - " + (editorData[0] & 0xFF) + " | " + (editorData[2] & 0xFF));
          
          delay(1000);
        }
        else if(editorData[1] == 0 && editorData[3] == 0)  // set x2 and y2; save to mapData array
        {
          editorData[1] = byte(mouseX / 5);
          editorData[3] = byte(mouseY / 3.75);
          mapData[editorElement * 8] = editorData[0];
          mapData[editorElement * 8 + 1] = editorData[1];
          mapData[editorElement * 8 + 2] = editorData[2];
          mapData[editorElement * 8 + 3] = editorData[3];
          mapData[editorElement * 8 + 4] = editorData[4];
          mapData[editorElement * 8 + 5] = editorData[5];
          mapData[editorElement * 8 + 6] = editorData[6];
          mapData[editorElement * 8 + 7] = editorData[7];
          
          print("\r\n 2nd - " + (editorData[1] & 0xFF) + " | " + (editorData[3] & 0xFF));
          
          editorData[0] = 0;
          editorData[1] = 0;
          editorData[2] = 0;
          editorData[3] = 0;
          
          delay(1000);
        }
      }
    }
  }
  else  // normal runtime handling (or editor setting lower than 0)
  {
    onSelection = false;  // generally cursor not on a path or object
    for(i = 0; i < 8; i++)  // check for each object
    {
      //check if mouse is on a path or object
      if(mapDataInt[i * 8] * 5 <= mouseX && mapDataInt[i * 8 + 1] * 5 >= mouseX && mapDataInt[i * 8 + 2] * 3.75 <= mouseY && mapDataInt[i * 8 + 3] * 3.75 >= mouseY)
      {
        if(i < 4)  //check object type and display appropriate pointer
        {
          image(mousePointer[1], mouseX - mousePointerMinus, mouseY - mousePointerMinus);
        }
        else
        {
          image(mousePointer[2], mouseX - mousePointerMinus, mouseY - mousePointerMinus);
        }
        
        if(mousePressed)  // handle if path/object is clicked
        {
          if(mapDataInt[i * 8 + 7] == 0)  // state is 0
          {
            mapX = mapDataInt[i * 8 + 4];
            mapY = mapDataInt[i * 8 + 5];
            mapSub = mapDataInt[i * 8 + 6];
          }
          else  // state is NOT 0
          {
            stateChangeHandler(mapDataInt[i * 8 + 7]);
          }
          
          swap();  // swap to new
          
          delay(delayTime);  // delay for specified time
        }
        
        onSelection = true;  // cursor is on selection
        break;
      }
    }
    
    if(!onSelection)  // display default pointer if not on selection
    {
      image(mousePointer[0], mouseX - mousePointerMinus, mouseY - mousePointerMinus);
    }
    
    image(loadIcon, 0, 0);
    image(saveIcon, 1215, 0);
    image(updateIcon, 607, 0);
    
    if(mousePressed && mouseY < 64)  // check if load/save icon is clicked
    {
      if(mouseX < 64)  // load
      {
        background(0);
        textSize(42);
        fill(255);
        text("Are you sure that you want to load your saved game?", 180, 280);
        image(yesIcon, 0, 895);
        image(noIcon, 1215, 895);
        prompt = 1;
      }
      else if(mouseX >= 1215)  // save
      {
        background(0);
        textSize(42);
        fill(255);
        text("Are you sure that you want to save your current game?", 172, 280);
        text("Existing saves will be overwritten!", 324, 360);
        image(yesIcon, 0, 895);
        image(noIcon, 1215, 895);
        prompt = 2;
      }
      else if(mouseX >= 607 && mouseX < 671)  // update
      {
        background(0);
        textSize(18);
        fill(255);
        text(applicationIdentifier + ":" + version[0] + "." + version[1], 0, 16);
        textSize(42);
        text("Do you want to check online for application updates?", 178, 280);
        text("An internet connection is required!", 324, 360);
        image(yesIcon, 0, 895);
        image(noIcon, 1215, 895);
        prompt = 3;
      }
    }
  }
  
  return;
}

void stateChangeHandler(int stateIn)  // handle statet changes; run corresponding "events"
{
  inventory[stateIn] = 1;
  mapSub = 0;
  
  switch(stateIn)
  {
    case 1:  // key 1
      mapState[126][129] = 1;
      mapState[63][63] = 1;
      break;
    
    case 2:  // lighter
      mapState[127][128] = 1;
      mapState[59][65] = 1;
      break;
    
    case 3:  // key 2
      mapState[60][63] = 1;
      mapState[62][65] = 1;
      break;
    
    case 4:  // money
      mapState[59][65] = 2;
      mapState[63][66] = 1;
      mapState[66][66] = 1;
      break;
    
    case 5:  // mobile phone
      mapState[68][67] = 1;
      mapState[65][66] += 2;
      break;
    
    case 6:  // train ticket
      mapState[66][66] = 2;
      mapState[65][66]++;
      break;
  }
  
  swap();
  return;
}

void swap()  // load data of the new tile
{
  //load files
  current = loadImage("data/map/" + applicationIdentifier + "/" + mapX + "-" + mapY + "-" + mapSub + "-" + (mapState[mapX][mapY] & 0xFF) + ".png");
  mapData = loadBytes("data/map/" + applicationIdentifier + "/" + mapX + "-" + mapY + "-" + mapSub + "-" + (mapState[mapX][mapY] & 0xFF) + ".dat");
  if(current != null && mapData == null && editor)  // generate empty .dat file if conditions are met
  {
    saveBytes("data/map/" + applicationIdentifier + "/" + mapX + "-" + mapY + "-" + mapSub + "-" + (mapState[mapX][mapY] & 0xFF) + ".dat", new byte[64]);
    mapData = loadBytes("data/map/" + applicationIdentifier + "/" + mapX + "-" + mapY + "-" + mapSub + "-" + (mapState[mapX][mapY] & 0xFF) + ".dat");
  }
  
  if(current == null || mapData == null)  // go back to default values if files can't be found
  {
    mapX = defaults[0];
    mapY = defaults[1];
    mapSub = defaults[2];
    mapState[mapX][mapY] = default3;
    swap();
    return;
  }
  
  for(i = 0; i < 8; i++)  // load byte data to integers
  {
    mapDataInt[i * 8] = mapData[i * 8] & 0xFF;
    mapDataInt[i * 8 + 1] = mapData[i * 8 + 1] & 0xFF;
    mapDataInt[i * 8 + 2] = mapData[i * 8 + 2] & 0xFF;
    mapDataInt[i * 8 + 3] = mapData[i * 8 + 3] & 0xFF;
    mapDataInt[i * 8 + 4] = mapData[i * 8 + 4] & 0xFF;
    mapDataInt[i * 8 + 5] = mapData[i * 8 + 5] & 0xFF;
    mapDataInt[i * 8 + 6] = mapData[i * 8 + 6] & 0xFF;
    mapDataInt[i * 8 + 7] = mapData[i * 8 + 7] & 0xFF;
  }
  
  if(editor)  // reset editor changes and data if required
  {
    for(i = 0; i < 8; i++)
    {
      editorData[i] = 0;
    }
  }
  
  return;
}

void loadGame()  // load game from save
{
  musicAudio.stop();
  
  location = loadBytes("save/" + applicationIdentifier + "/" + saveSlot + "/loc.sav");  // load values from files
  if(location == null)  // no save available
  {
    print("No save found!");
    musicAudio.loop();
    return;
  }
  
  inventory = loadBytes("save/" + applicationIdentifier + "/" + saveSlot + "/inv.sav");
  for(i = 0; i < 255; i++)
  {
    mapState[i] = loadBytes("save/" + applicationIdentifier + "/" + saveSlot + "/map" + i + ".sav");
  }
  
  mapX = location[0] & 0xFF;  // parse location values
  mapY = location[1] & 0xFF;
  mapSub = location[2] & 0xFF;
  
  swap();  // swap to saved position
  
  delay(1000);
  
  musicAudio.loop();
  
  return;
}

void saveGame()  // save game
{
  musicAudio.stop();
  
  location[0] = byte(mapX);  // mapX, mapY and mapSub to byte
  location[1] = byte(mapY);
  location[2] = byte(mapSub);
  
  saveBytes("save/" + applicationIdentifier + "/" + saveSlot + "/loc.sav", location);  // save values to files
  saveBytes("save/" + applicationIdentifier + "/" + saveSlot + "/inv.sav", inventory);
  for(i = 0; i < 255; i++)
  {
    saveBytes("save/" + applicationIdentifier + "/" + saveSlot + "/map" + i + ".sav", mapState[i]);
  }
  
  delay(1000);
  
  musicAudio.loop();
  
  return;
}

void updateCheck()
{
  musicAudio.stop();
  
  byte[] tempVer = loadBytes("http://beta.techcrafter.de/" + applicationIdentifier + "/latest.info");
  
  background(0);
  textSize(42);
  fill(255);
  
  if(tempVer == null)  // unable to connect
  {
    print("\r\nConnection error!");
    
    text("There was a problem checking for application updates!", 172, 280);
    text("Please check you network connection.", 318, 360);
  }
  else if(tempVer[0] == version[0] && tempVer[1] == version[1])  // latest version
  {
    print("\r\nLatest version!");
    
    text("You are already using the latest application version!", 172, 280);
  }
  else  // NOT latest version
  {
    print("\r\nPlease update!");
    
    text("You are not playing the latest version of " + applicationIdentifier + ".", 174, 280);
    text("Please consider updating on itch.io!", 318, 360);
  }
  
  prompt = 4;
  
  return;
}

void credits()  // credits
{
  if(creditsFrame == 0)
  {
    musicAudio.stop();
    current = loadImage("data/map/" + applicationIdentifier + "/" + mapX + "-" + mapY + "-" + mapSub + "-" + (mapState[mapX][mapY] & 0xFF) + ".png");
  }
  
  if(creditsFrame <= 255)
  {
    tint(255, 255, 255, 0 + creditsFrame);
    image(current, 0, 0);
  }
  else
  {
    tint(255, 255, 255);
    image(current, 0, 0);
    delay(6000);
    mapX = 65;
    mapY = 66;
    mapState[255][255] = 1;
    musicAudio.loop();
    swap();
    creditsFrame = 0;
    return;
  }
  
  delay(10);
  creditsFrame++;
  return;
}

void keyPressed()  // function runs when pressing a key; only used for the editor
{
  if(key == CODED && editor)
  {
    switch(keyCode)  // read keyCode's and handle changes correspondingly
    {
      case UP:  // arrow keys
        if(editorSelection == 0)
        {
          mapX++;
        }
        else if(editorSelection == 1)
        {
          mapY++;
        }
        else if(editorSelection == 2)
        {
          mapSub++;
        }
        else if(editorSelection == 3)
        {
          mapState[mapX][mapY]++;
        }
        else if(editorSelection == 4)
        {
          editorElement++;
        }
        else if(editorSelection >= 5 && editorSelection <= 8)
        {
          editorData[editorSelection - 1]++;
        }
        break;
      
      case DOWN:
        if(editorSelection == 0)
        {
          mapX--;
        }
        else if(editorSelection == 1)
        {
          mapY--;
        }
        else if(editorSelection == 2)
        {
          mapSub--;
        }
        else if(editorSelection == 3)
        {
          mapState[mapX][mapY]--;
        }
        else if(editorSelection == 4)
        {
          editorElement--;
        }
        else if(editorSelection >= 5 && editorSelection <= 8)
        {
          editorData[editorSelection - 1]--;
        }
        break;
      
      case LEFT:
        editorSelection--;
        break;
      
      case RIGHT:
        editorSelection++;
        break;
    }
  }
  else if(key == DELETE)
  {
    if(editorSelection == 4)  // delete key on editorSelection 4 saves current changes to the selected .dat file; USE WITH CAUTION!
    {
      saveBytes("data/map/" + applicationIdentifier + "/" + mapX + "-" + mapY + "-" + mapSub + "-" + (mapState[mapX][mapY] & 0xFF) + ".dat", mapData);
      print("\r\nSave!");
    }
    else  // discard changes
    {
      print("\r\nNO SAVE!");
    }
    swap();  // swap to selected tile
  }
  
  return;
}
