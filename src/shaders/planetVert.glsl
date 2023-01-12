uniform float time;

varying vec3 texcoord;
varying vec3 newnormal;
varying vec3 plancoord;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
attribute vec3 position;
attribute vec3 normal;

// The vertex shader
void main()
{
	texcoord = position;
	plancoord = vec3(projectionMatrix * vec4( position, 1.0 ));
	//newnormal = (modelViewMatrix * vec4(normal,0.0)).xyz;
	newnormal = normal;
    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}