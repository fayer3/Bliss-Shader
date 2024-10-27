#version 120

#include "/lib/settings.glsl"

#ifdef LPV_SHADOWS
	#include "/lib/cube/cubeData.glsl"
	flat in int render;
	in vec2 Ftexcoord;
	uniform sampler2D tex;
#endif

//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	#ifdef LPV_SHADOWS
		if (render >= 0 && (
			any(lessThan(gl_FragCoord.xy, minBounds[render >> 4] + renderBounds[render  & 15])) ||
			any(greaterThan(gl_FragCoord.xy, maxBounds[render >> 4] + renderBounds[render & 15]))))
			{
			discard;
			return;
		}
		gl_FragData[0] = vec4(texture2D(tex,Ftexcoord.xy).rgb, texture2DLod(tex, Ftexcoord.xy, 0).a);
	#else
		gl_FragData[0] = vec4(0.0);
	#endif
}
