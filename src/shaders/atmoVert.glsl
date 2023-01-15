varying vec3 vNormal;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec3 atmoColor;
attribute vec3 position;
attribute vec3 normal;

// The vertex shader
void main()
{
	vNormal = normalize((modelViewMatrix * vec4(normal,0.0)).xyz);
    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}