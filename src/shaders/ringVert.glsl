varying vec3 texcoord;
varying vec3 newnormal;

// The vertex shader
void main()
{
	texcoord = position;
	newnormal = normalize((modelViewMatrix * vec4(normal,0.0)).xyz);
	//newnormal = normal;
    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}