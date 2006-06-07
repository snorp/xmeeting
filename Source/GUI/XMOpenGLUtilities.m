/*
 * $Id: XMOpenGLUtilities.m,v 1.3 2006/06/07 10:50:18 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#include "XMOpenGLUtilities.h"

Vector3 XMMakeVector3(GLfloat x, GLfloat y, GLfloat z)
{
	Vector3 res;
	res.x = x;
	res.y = y;
	res.z = z;
	return res;
}

Placement XMMakePlacement(Vector3 pos, Vector3 scale, Vector3 rot, GLfloat rotAngle)
{
	Placement res;
	res.position = pos;	
	res.rotationAxis = rot;	
	res.scaling = scale;	
	res.rotationAngle = rotAngle;	
	res.isReflected = NO;
	return res;
}

Camera XMMakeCamera(Vector3 eye, Vector3 sceneCenter, Vector3 up)
{
	Camera res;
	res.eye = eye;
	res.sceneCenter = sceneCenter;
	res.upVector = up;
	return res;
}

void outputCharacter(float x, float y, float z, char *string)
{
	int len, i;
	glRasterPos3f(x, y, z);
	len = (int) strlen(string);
	for (i = 0; i < len; i++) {
		glutBitmapCharacter(GLUT_BITMAP_9_BY_15, string[i]);
	}
}

//Debug methods
NSString* XMStringFromCamera(Camera* camera)
{
	return [NSString stringWithFormat:@"\tEye: %f, %f, %f\n\tCenter: %f, %f, %f\n\tup Vector: %f, %f, %f",
										camera->eye.x, camera->eye.y, camera->eye.z,
										camera->sceneCenter.x, camera->sceneCenter.y, camera->sceneCenter.z,
										camera->upVector.x, camera->upVector.y, camera->upVector.z];
}

NSString* XMStringFromPlacement(Placement* placement)
{
	return [NSString stringWithFormat:@"\tPosition: %f, %f, %f\n\tRotation Axis: %f, %f, %f\n\tScaling: %f, %f, %f\n\tRotation Angle: %f, Reflected: %@",
		placement->position.x, placement->position.y, placement->position.z,
		placement->rotationAxis.x, placement->rotationAxis.y, placement->rotationAxis.z,
		placement->scaling.x, placement->scaling.y, placement->scaling.z,
		placement->rotationAngle,
		(placement->isReflected ? @"YES": @"NO")];
	
}

NSString* XMStringFromScene(Scene* scene){
	return [NSString stringWithFormat:@"\tCamera:\n%@\nLocal Video:\n%@\nRemote Video:\n%@",
										XMStringFromCamera(&(scene->camera)),
										XMStringFromPlacement(&(scene->localVideoPlacement)),
										XMStringFromPlacement(&(scene->remoteVideoPlacement))];
}

void drawAxisAt(GLfloat x, GLfloat y, GLfloat z)
{
	glColor3f(1.0, 0,0.0);
	glLoadIdentity(); //no transformation
	glBegin(GL_LINES);
	glVertex3f(x -1.8f, y, z);
	glVertex3f(x + 1.8f, y, z);
	glEnd();
	glColor3f(0.0,1.0,0.0);
	
	glBegin(GL_LINES);
	glVertex3f(x, y -1.8f, z);
	glVertex3f(x, y+ 1.8f, z);
	glEnd();
	
	glColor3f(0.0, 0,1.0);
	glBegin(GL_LINES);
	glVertex3f(x, y, z - 1.8f);
	glVertex3f(x, y, z);
	glEnd();
	
	char s[100];	    // label axes
	glColor3f (0.0, 0.0, 1.0);
	sprintf(s,"+z");
	outputCharacter(x, y, z +0.5f, s);
	
	sprintf(s,"-z");
	glColor3f(1.0,0.0,0.0);
	outputCharacter(x, y, z - 0.5f, s);
	
	sprintf(s,"+x");
	outputCharacter(x + 0.5, y, z, s);
	sprintf(s,"-x");		
	glColor3f(0.0, 1,0.0);
	outputCharacter(x - 0.5f, y, z, s);
	
	sprintf(s,"+y");
	outputCharacter(x + 0.0f, y + 0.5f, z, s);
	sprintf(s,"-y");
	outputCharacter(x, y - 0.5f, z, s);
}
