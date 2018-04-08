import processing.serial.*;
import java.awt.datatransfer.*;
import java.awt.Toolkit;
import java.util.*;
import processing.opengl.*;
import saito.objloader.*;
import g4p_controls.*;
import org.ejml.data.DenseMatrix64F;
import org.ejml.ops.CommonOps;
import org.ejml.ops.NormOps;
import java.sql.Timestamp;
import shapes3d.utils.*;
import shapes3d.animation.*;
import shapes3d.*;

Rot lastQuaternion;
float roll  = 0.0F;
float pitch = 0.F;
float yaw   = 0.0F;
float temp  = 0.0F;
float alt   = 0.0F;
MadgwickAHRS m = new MadgwickAHRS(1000f);
PImage img;
PShape s;
PVector magneticField, accelerometer, gyroscope;

List<String> calibrationData = new ArrayList<String>();
;

// Serial port state.
Serial       port;
String       buffer = "";
final String serialConfigFile = "serialconfig.txt";
boolean      printSerial = false;

// UI controls.
GPanel    configPanel;
GDropList serialList;
GLabel    serialLabel;
GLabel    statLabel;
GCheckbox printSerialCheckbox;

void setup()
{

  lastQuaternion = new Rot(new PVector(0, 0, 1), radians(85));
  textAlign(LEFT, BOTTOM);
  textSize(28);
  size(1024, 576, P3D);
  frameRate(60);
  s = loadShape("logo.svg");
  img = loadImage("background.jpg");
  accelerometer = new PVector();
  magneticField = new PVector();
  gyroscope = new PVector();
  // Serial port setup.
  // Grab list of serial ports and choose one that was persisted earlier or default to the first port.
  int selectedPort = 0;
  String[] availablePorts = Serial.list();
  if (availablePorts == null) {
    println("ERROR: No serial ports available!");
    exit();
  }
  String[] serialConfig = loadStrings(serialConfigFile);
  if (serialConfig != null && serialConfig.length > 0) {
    String savedPort = serialConfig[0];
    // Check if saved port is in available ports.
    for (int i = 0; i < availablePorts.length; ++i) {
      if (availablePorts[i].equals(savedPort)) {
        selectedPort = i;
      }
    }
  }
  // Build serial config UI.
  configPanel = new GPanel(this, 10, 10, width-20, 90, "Configuration (click to hide/show)");
  serialLabel = new GLabel(this, 0, 20, 80, 25, "Serial port:");
  // statLabel = new GLabel(this, 0, 70, 80, 25, "Waiting...");
  configPanel.addControl(serialLabel);
  serialList = new GDropList(this, 90, 20, 200, 200, 6);
  serialList.setItems(availablePorts, selectedPort);
  configPanel.addControl(serialList);
  printSerialCheckbox = new GCheckbox(this, 5, 50, 200, 20, "Print serial data");
  printSerialCheckbox.setSelected(printSerial);
  configPanel.addControl(printSerialCheckbox);
  // configPanel.addControl(statLabel);
  // Set serial port.
  setSerialPort(serialList.getSelectedText());
}
public class Sensor {
  static final int TYPE_ACCELEROMETER  = 1;
  static final int TYPE_GYROSCOPE = 2;
  static final int TYPE_MAGNETIC_FIELD = 3;
  static final int TYPE_QUATERNION = 4;
}
void draw()
{
  background(img);
  // Set a new co-ordinate space
  pushMatrix();

  // Simple 3 point lighting for dramatic effect.
  // Slightly red light in upper right, slightly blue light in upper left, and white light from behind.
  pointLight(255, 200, 200, 400, 400, 500);
  pointLight(200, 200, 255, -400, 400, 500);
  pointLight(255, 255, 255, 0, 0, -500);

  // Displace objects from 0,0
  translate(width/2, height/2);


  PVector dir = new PVector(100, 0, 0);
  // Initialise first line
  PVector start = new PVector();
  PVector end = start.get();
  end.add( dir );
  // draw firts bit of line

  lastQuaternion.applyTo(end);
  stroke(255, 0, 0);
  line(start.x, start.y, start.z, end.x, end.y, end.z);
  //translate(1024/2, 576/2, 0);

  // Rotate shapes around the X/Y/Z axis (values in radians, 0..Pi*2)
  rotateX(radians(roll));
  rotateZ(radians(pitch));
  rotateY(radians(yaw));

  pushMatrix();
  noStroke();
  //shape(s, 250, -370, 400, 300);
  //model.draw();
  //texture(img);
  box(300f, 50f, 200f);
  popMatrix();
  popMatrix();
  fill(0, 255, 0);
  textSize(20);
  text("Accelerometer(g): "
    + "x: " + nfp(accelerometer.x, 1, 2) + ", " 
    + "y: " + nfp(accelerometer.y, 1, 2) + ", " 
    + "z: " + nfp(accelerometer.z, 1, 2) + "\n"
    + "Gyroscope(deg/s): " 
    + "x: " + nfp(gyroscope.x, 1, 2) + ", "
    + "y: " + nfp(gyroscope.y, 1, 2) + ", " 
    + "z: " + nfp(gyroscope.z, 1, 2) + "\n"
    + "MagneticField(mG): " 
    + "x: " + nfp(magneticField.x, 1, 2) + ", "
    + "y: " + nfp(magneticField.y, 1, 2) + ", " 
    + "z: " + nfp(magneticField.z, 1, 2) + "\n"
    + "Orientation: " + "" 
    + "azimuth: " + yaw + ", "
    + "pitch: " + pitch + ", " 
    + "roll: " + roll + "\n"
    , 20, 0, width, height);
  //print("draw");
}

void serialEvent(Serial p) 
{
  String incoming = p.readString();
  if (printSerial) {
    println(incoming);
  }
  try {
  if ((incoming.length() > 8))
  { 
    String[] list = split(incoming, " ");
    if ( (list.length > 0) && (list[0].equals("Or:")) ) 
    {
      float[] values = new float[3];
      for (int i = 1; i < list.length; ++i) {
        values[i-1] = Float.parseFloat(list[i]);
      }
      yaw=values[0];
      pitch=values[1];
      roll=values[2];
      buffer = incoming;
    }

    if ( (list.length > 0) && (list[0].equals("Accel:")) ) 
    {
      float[] values = new float[3];
      for (int i = 1; i < list.length; ++i) {
        values[i-1] = Float.parseFloat(list[i]);
      }
      sensorValuesAcquired(Sensor.TYPE_ACCELEROMETER, values);
      buffer = incoming;
    }
    if ( (list.length > 0) && (list[0].equals("Gyro:")) ) 
    {
      float[] values = new float[3];
      for (int i = 1; i < list.length; ++i) {
        values[i-1] = Float.parseFloat(list[i]);
      }
      sensorValuesAcquired(Sensor.TYPE_GYROSCOPE, values);
      buffer = incoming;
    }
    if ( (list.length > 0) && (list[0].equals("Mag:")) ) 
    {
      float[] values = new float[3];
      for (int i = 1; i < list.length; ++i) {
        values[i-1] = Float.parseFloat(list[i]);
      }
      sensorValuesAcquired(Sensor.TYPE_MAGNETIC_FIELD, values);
      buffer = incoming;
    } 
    if ( (list.length > 0) && (list[0].equals("q:")) ) 
    {
      float[] values = new float[4];
      for (int i = 1; i < list.length; ++i) {
        values[i-1] = Float.parseFloat(list[i]);
      }
      sensorValuesAcquired(Sensor.TYPE_QUATERNION, values);
      buffer = incoming;
    }
    if ( (list.length > 0) && (list[0].equals("Temp:")) ) 
    {
      temp  = float(list[1]);
      buffer = incoming;
    }
  }
  } catch (Exception e) {
  }
}
void sensorValuesAcquired (int etype, float[] values) {
  try {

    /*Timestamp timestamp = new Timestamp(System.currentTimeMillis());
     long time = timestamp.getTime();
     float dt=0; */
    switch (etype) {
    case Sensor.TYPE_ACCELEROMETER:
      accelerometer.set(values[0], values[1], values[2]);
      break;
    case  Sensor.TYPE_GYROSCOPE:
      gyroscope.set(values[0], values[1], values[2]);
      break;
    case Sensor.TYPE_MAGNETIC_FIELD:
      calibrationData.add(values[0] + "," + values[1] + "," + values[2]);
      String[] stringArray = new String[ calibrationData.size() ];
      calibrationData.toArray(stringArray);
      saveStrings("dataTest.txt", stringArray);
      magneticField.set(values[0], values[1], values[2]);
      // calculateOrientation(false);
      break;
    case Sensor.TYPE_QUATERNION:
      lastQuaternion= new Rot(new PVector(values[1], values[2], values[3]), values[0]);
      break;
    }
  }
  catch (Exception e) {
    println("Error parsing:");
    e.printStackTrace();
  }
}
void calculateOrientation(boolean degrees)
{
  try {
    m.update(radians(gyroscope.x), radians(gyroscope.y), radians(gyroscope.z), accelerometer.x, accelerometer.y, accelerometer.y);
    float quarternions[] = m.getQuaternion();
    float dqw = quarternions[0];
    float dqx = quarternions[1];
    float dqy = quarternions[2];
    float dqz = quarternions[3];
    float ysqr = dqy * dqy;
    float t0 = -2.0f * (ysqr + dqz * dqz) + 1.0f;
    float t1 = +2.0f * (dqx * dqy - dqw * dqz);
    float t2 = -2.0f * (dqx * dqz + dqw * dqy);
    float t3 = +2.0f * (dqy * dqz - dqw * dqx);
    float t4 = -2.0f * (dqx * dqx + ysqr) + 1.0f;
    // Keep t2 within range of asin (-1, 1)
    t2 = t2 > 1.0f ? 1.0f : t2;
    t2 = t2 < -1.0f ? -1.0f : t2;

    pitch = asin(t2) * 2;
    roll = atan2(t3, t4);
    yaw = atan2(t1, t0);

    if (degrees)
    {
      pitch *= (180.0 / PI);
      roll *= (180.0 / PI);
      yaw *= (180.0 / PI);
      if (pitch < 0) pitch = 360.0 + pitch;
      if (roll < 0) roll = 360.0 + roll;
      if (yaw < 0) yaw = 360.0 + yaw;
    }
  } 
  catch(Exception e) {
    println("Error calculating:");
    e.printStackTrace();
  }
  /*
  try {
   boolean success = getRotationMatrix(
   matrixR, 
   matrixI, 
   accelerometer.array(), 
   magneticField.array());
   
   if (success) {
   getOrientation(matrixR, matrixValues);
   
   yaw = matrixValues[0];
   pitch = matrixValues[1];
   roll = matrixValues[2];
   }
   }
   catch (Exception e) { 
   println("Error: " + e);
   }*/
}

// Set serial port to desired value.
void setSerialPort(String portName) {
  // Close the port if it's currently open.
  if (port != null) {
    port.stop();
  }
  try {
    // Open port.
    port = new Serial(this, portName, 38400);
    port.bufferUntil('\n');
    // Persist port in configuration.
    saveStrings(serialConfigFile, new String[] { portName });
  }
  catch (RuntimeException ex) {
    println(ex);
    // Swallow error if port can't be opened, keep port closed.
    port = null;
  }
}

// UI event handlers

void handlePanelEvents(GPanel panel, GEvent event) {
  // Panel events, do nothing.
}

void handleDropListEvents(GDropList list, GEvent event) { 
  // Drop list events, check if new serial port is selected.
  if (list == serialList) {
    setSerialPort(serialList.getSelectedText());
  }
}

void handleToggleControlEvents(GToggleControl checkbox, GEvent event) { 
  // Checkbox toggle events, check if print events is toggled.
  if (checkbox == printSerialCheckbox) {
    printSerial = printSerialCheckbox.isSelected();
  }
}