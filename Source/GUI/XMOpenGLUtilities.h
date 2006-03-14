/*
 * $Id: XMOpenGLUtilities.h,v 1.1 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */
 
#ifndef __XM_OGL_UTILITIES_H__
#define __XM_OGL_UTILITIES_H__

#define ROTATION_AXIS_X XMMakeVector3(1.0, 0.0, 0.0)
#define ROTATION_AXIS_Y XMMakeVector3(0.0, 1.0, 0.0)
#define ROTATION_AXIS_Z XMMakeVector3(0.0, 0.0, 1.0)

#define NO_SCALING XMMakeVector3(1.0, 1.0, 1.0)
#define POSITION_CENTERED XMMakeVector3(0.0, 0.0, 0.0)

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <GLUT/glut.h>


//Datastructure to store spatial positioning and rotation of a polygon
//Used for storing PinP modes and video displacement in the 3D space
struct Vector3{
	GLfloat x, y, z;
};

typedef struct{
	struct Vector3 eye;
	struct Vector3 sceneCenter;
	struct Vector3 upVector;
} Camera;

typedef struct _Placement{
	struct Vector3 position;
	struct Vector3 rotationAxis;
	struct Vector3 scaling;
	GLfloat rotationAngle;
	BOOL isReflected;
} Placement;

typedef struct _Scene{
	Camera camera;
	Placement localVideoPlacement;
	Placement remoteVideoPlacement;
} Scene;

//Convenience functions to work with the above datastructures
struct Vector3 XMMakeVector3(GLfloat x, GLfloat y, GLfloat z);

Placement XMMakePlacement(struct Vector3 pos, struct Vector3 scale, struct Vector3 rot, GLfloat rotAngle);

Camera XMMakeCamera(struct Vector3 eye, struct Vector3 sceneCenter, struct Vector3 up);

NSString* XMStringFromScene(Scene* scene);

void outputCharacter(float x, float y, float z, char *string);

void drawAxisAt(GLfloat x, GLfloat y, GLfloat z);

#endif