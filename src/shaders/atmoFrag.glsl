precision highp float;
uniform vec3 cameraPos; // The position of the camera
uniform float atmosphereRadius; // The radius of the atmosphere
uniform vec3 planetCenter; // The center of the planet
uniform vec3 sunPos; // The position of the sun
uniform vec3 atmoColor;

varying vec3 vNormal; // The surface normal of the sphere
varying vec3 vCamera; // The direction from the surface to the camera
varying vec3 vSun; // The direction from the surface to the sun

void main() {
  
  //Lighting
	vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0) - vec3(0.0));

  // Front/Back Lighting
  vec3 YELLOW = vec3(1.0, 0.9, 0.7);
  vec3 RED = vec3(0.035, 0.0, 0.0);


  float intensity = pow(0.8 - dot(vNormal, vec3(0.0,0.0, 1.0)), 2.0);
  vec3 atmosphere = atmoColor * pow(intensity, 1.5);

  gl_FragColor = vec4(atmosphere, intensity); 
}