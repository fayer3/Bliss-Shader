#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/cube/cubeData.glsl"

#ifdef TRANSLUCENT_COLORED_SHADOWS
varying vec3 Fcolor;
#else
const vec3 Fcolor = vec3(1.0);
#endif

varying vec2 Ftexcoord;
uniform sampler2D tex;
uniform sampler2D noisetex;

flat in int render;

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

float blueNoise(){
  return fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy)%512, 0).a + 1.0/1.6180339887 );
}


void main() {
	if (render >= 0 && (any(lessThan(gl_FragCoord.xy, minBounds[render >> 4] + renderBounds[render  & 15])) || any(greaterThan(gl_FragCoord.xy, maxBounds[render >> 4] + renderBounds[render & 15])))) {
		discard;
		return;
	}
	gl_FragData[0] = vec4(texture2D(tex,Ftexcoord.xy).rgb * Fcolor.rgb,  texture2DLod(tex, Ftexcoord.xy, 0).a);

  	#ifdef Stochastic_Transparent_Shadows
		if(gl_FragData[0].a < blueNoise()) { discard; return;}
  	#endif
}
