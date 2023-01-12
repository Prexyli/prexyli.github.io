uniform float time;

varying vec3 texcoord;
varying vec3 newnormal;
//uniform mat4 modelViewMatrix;
//uniform mat4 projectionMatrix;

uniform vec3 color1;
uniform vec3 color2;
uniform vec3 color3;
uniform vec3 color4;

//attribute vec3 position;
//attribute vec3 normal;

// The vertex shader
void main()
{
	texcoord = position;
	newnormal = normalize((modelViewMatrix * vec4(normal,0.0)).xyz);
	//newnormal = normal;
    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}