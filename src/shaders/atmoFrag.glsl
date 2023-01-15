precision highp float;
uniform vec3 atmoColor;

varying vec3 vNormal; // The surface normal of the sphere

void main() {
  
  //Lighting
	vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0) - vec3(0.0));

  float intensity = pow(0.8 - dot(vNormal, vec3(0.0,0.0, 1.0)), 2.0);
  vec3 atmosphere = atmoColor * pow(intensity, 1.5);

  gl_FragColor = vec4(atmosphere, intensity); 
}