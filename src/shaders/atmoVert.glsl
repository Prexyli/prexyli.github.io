
varying vec3 texcoord;
varying vec3 vNormal;
varying vec3 vCamera;
varying vec3 vSun;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
attribute vec3 position;
attribute vec3 normal;

// The vertex shader
void main()
{
	texcoord = position;
	vNormal = normalize((modelViewMatrix * vec4(normal,0.0)).xyz);
	vCamera = vec3(modelViewMatrix * vec4(position, 1.0));
	vSun = position - vec3(1.0, 1.0, 1.0);
    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}