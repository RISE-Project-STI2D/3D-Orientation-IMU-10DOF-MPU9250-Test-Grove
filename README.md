# 3D-Orientation-IMU-10DOF-MPU9250-Test-Grove
Display the 3D orientation of the IMU device using processing and an Arduino board

## Introduction

In order to make a 3D simulation of a Robot, I first made some tests with [Processing](https://processing.org/), a visual art engine.
I also forked a sketch from  [https://github.com/kriswiner/MPU9250](https://github.com/kriswiner/MPU9250/blob/master/MPU9250_BMP280_BasicAHRS_t3.ino).

### Video

[![IMAGE ALT TEXT HERE](https://images.streamable.com/east/image/nwq73_1.jpg?height=100)](https://streamable.com/nwq73)

### Change dones on kriswiner's sketch

I have made some change to the Arduino Sketch:

+ In order to receive the orientation & some infos, the arduino board print serial infos.
+ I made a new var for the informations printing interval. 

## Components

I'm using a [IMU 10DOF Grove](http://wiki.seeedstudio.com/Grove-IMU_10DOF_v2.0/) from Seed Studio working in I2C mode. That IMU integrate the MPU9250 gyro/accel/mag(AK8963) & a pressure sensor (BMP280)

## Git structure

Arduino code is located in `IMU_Arduino`
The processing project is located in ProcessingIMU3DProject. I used the version 3.3.6 of Processing to make that sketch.

## remaining problems

As you can see, the orientation is not in relation with the screen, it's sort of inverted


