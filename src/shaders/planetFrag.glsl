precision highp float;
uniform float time;
uniform mat4 modelViewMatrix;

uniform vec3 color1;
uniform vec3 color2;
uniform vec3 color3;
uniform vec3 color4;
uniform vec3 color5;

uniform float rMult;
uniform float qMult;
uniform float vMult;
uniform float amplitude;
uniform bool fbmfunc;

varying vec3 texcoord;
varying vec3 newnormal;


// psrdnoise (c) Stefan Gustavson and Ian McEwan,
// ver. 2021-12-02, published under the MIT license:
// https://github.com/stegu/psrdnoise/

vec4 permute(vec4 i) {
	vec4 im = mod(i, 289.0);
	return mod(((im*34.0)+10.0)*im, 289.0);
}

float psrdnoise(vec3 x, vec3 period, float alpha, out vec3 gradient)
{
	const mat3 M = mat3(0.0, 1.0, 1.0, 1.0, 0.0, 1.0,  1.0, 1.0, 0.0);
	const mat3 Mi = mat3(-0.5, 0.5, 0.5, 0.5,-0.5, 0.5, 0.5, 0.5,-0.5);
	vec3 uvw = M * x;
	vec3 i0 = floor(uvw), f0 = fract(uvw);
	vec3 g_ = step(f0.xyx, f0.yzz), l_ = 1.0 - g_;
	vec3 g = vec3(l_.z, g_.xy), l = vec3(l_.xy, g_.z);
	vec3 o1 = min( g, l ), o2 = max( g, l );
	vec3 i1 = i0 + o1, i2 = i0 + o2, i3 = i0 + vec3(1.0);
	vec3 v0 = Mi * i0, v1 = Mi * i1, v2 = Mi * i2, v3 = Mi * i3;
	vec3 x0 = x - v0, x1 = x - v1, x2 = x - v2, x3 = x - v3;
	if(any(greaterThan(period, vec3(0.0)))) {
		vec4 vx = vec4(v0.x, v1.x, v2.x, v3.x);
		vec4 vy = vec4(v0.y, v1.y, v2.y, v3.y);
		vec4 vz = vec4(v0.z, v1.z, v2.z, v3.z);
		if(period.x > 0.0) vx = mod(vx, period.x);
		if(period.y > 0.0) vy = mod(vy, period.y);
		if(period.z > 0.0) vz = mod(vz, period.z);
		i0 = floor(M * vec3(vx.x, vy.x, vz.x) + 0.5);
		i1 = floor(M * vec3(vx.y, vy.y, vz.y) + 0.5);
		i2 = floor(M * vec3(vx.z, vy.z, vz.z) + 0.5);
		i3 = floor(M * vec3(vx.w, vy.w, vz.w) + 0.5);
	}
	vec4 hash = permute( permute( permute( 
			vec4(i0.z, i1.z, i2.z, i3.z ))
			+ vec4(i0.y, i1.y, i2.y, i3.y ))
			+ vec4(i0.x, i1.x, i2.x, i3.x ));
	vec4 theta = hash * 3.883222077;
	vec4 sz = hash * -0.006920415 + 0.996539792;
	vec4 psi = hash * 0.108705628;
	vec4 Ct = cos(theta), St = sin(theta);
	vec4 sz_prime = sqrt( 1.0 - sz*sz );
	vec4 gx, gy, gz;
	if(alpha != 0.0) {
		vec4 px = Ct * sz_prime, py = St * sz_prime, pz = sz;
		vec4 Sp = sin(psi), Cp = cos(psi), Ctp = St*Sp - Ct*Cp;
		vec4 qx = mix( Ctp*St, Sp, sz), qy = mix(-Ctp*Ct, Cp, sz);
		vec4 qz = -(py*Cp + px*Sp);
		vec4 Sa = vec4(sin(alpha)), Ca = vec4(cos(alpha));
		gx = Ca*px + Sa*qx; gy = Ca*py + Sa*qy; gz = Ca*pz + Sa*qz;
	}
	else {
		gx = Ct * sz_prime; gy = St * sz_prime; gz = sz;  
	}
	vec3 g0 = vec3(gx.x, gy.x, gz.x), g1 = vec3(gx.y, gy.y, gz.y);
	vec3 g2 = vec3(gx.z, gy.z, gz.z), g3 = vec3(gx.w, gy.w, gz.w);
	vec4 w = 0.5-vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3));
	w = max(w, 0.0); vec4 w2 = w * w, w3 = w2 * w;
	vec4 gdotx = vec4(dot(g0,x0), dot(g1,x1), dot(g2,x2), dot(g3,x3));
	float n = dot(w3, gdotx);
	vec4 dw = -6.0 * w2 * gdotx;
	vec3 dn0 = w3.x * g0 + dw.x * x0;
	vec3 dn1 = w3.y * g1 + dw.y * x1;
	vec3 dn2 = w3.z * g2 + dw.z * x2;
	vec3 dn3 = w3.w * g3 + dw.w * x3;
	gradient = 39.5 * (dn0 + dn1 + dn2 + dn3);
	return 39.5 * n;
}


//
//
//


#define NUM_OCTAVES 10

float fbmH(vec3 x, float aconf) {
	float v = 0.5;
	float a = amplitude;
	vec3 p = vec3(0.0);
	vec3 g1;
	float alpha = aconf * time;
	for (int i = 0; i < NUM_OCTAVES; ++i) {
		v += a * psrdnoise(x, p, alpha, g1);
		x = x * 2.0;
		a *= 0.5;
	}
	return v;
}

float fbm2(vec3 inX, float inAlphaConf) {
	float h = 0.0;
	float H = 1.0/3.0;
	float G = exp2(-H);
	float f = 0.012;
	float a = 2.0*amplitude;
	vec3 p = vec3(0.0);
	float alpha = inAlphaConf * time;
	vec3 g;
	for( int i=0; i<NUM_OCTAVES; i++ )
	{
		h += a*psrdnoise(f*inX, p, alpha, g);
		f *= 2.0;
		a *= G;
	}
	return h;
}

void main()
{
	//Rescale the texcoords
	vec3 X = (texcoord + 2.0) / 4.0; 
	float distCenter = sqrt(pow(texcoord.y,2.0));
	float opacity = fbmH(vec3(distCenter),0.0);
	opacity *= 10.0;
	float intpart = floor(opacity);
	opacity = intpart / 10.0;
	// Warping with FBM
	vec3 q, r;
	float vh;
	if(fbmfunc){
		q = vec3(fbmH(X * qMult, 0.03) , 2.0*fbmH(X * qMult, 0.0), 2.0*fbmH(X * qMult,0.0));
		r = vec3(fbmH(X * rMult + q, 0.05), fbmH(X*rMult + q, 0.0), fbmH(X*rMult + q, 0.0));
		vh = fbmH(X * vMult * r, 0.0);
	}
	else {
		q = vec3(fbm2(X * qMult, 0.03) , 2.0*fbm2(X * qMult, 0.0), 2.0*fbm2(X * qMult,0.0));
		r = vec3(fbmH(X * rMult + q, 0.05), fbmH(X*rMult + q, 0.0), fbmH(X*rMult + q, 0.0));
		vh = fbm2(X * vMult * r, 0.0);
	}
	vec3 color;
	vec3 col1 = color1;
	vec3 col2 = color2;
	
	vec3 col3 = color3;
    vec3 col4 = color4;
    vec3 col5 = color5;

	vec3 col_mix = mix(col3, col4, clamp(r, 0.0, 1.0));
    col_mix = mix(col_mix, col5, clamp(q, 0.0, 1.0));

	float pos = vh * 2.0 - 1.0;
	color = mix(col_mix, col1, clamp(pos, 0.0, 1.0));
	color = mix(color, col2, clamp(-pos, 0.0, 1.0));

	color = (clamp((0.4 * pow(vh,3.) + pow(vh,2.) + 0.5*vh), 0.0, 1.0) * 0.9 + 0.1) * color;

	//Lighting
	vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0)-vec3(0.0));
	
	float ambient = 0.0;
	float diffuse = mix( max(0.0, dot( lightDir, newnormal)), 1.0, ambient);

	//Gamma correction
	color = pow(color, vec3(1./2.2));

	color = diffuse * color;

    gl_FragColor = vec4(color, 1.0);
	
}