#version 330 compatibility

layout (triangles) in;
layout (triangle_strip) out;

#include "/lib/settings.glsl"

#ifdef TRANSLUCENT_COLORED_SHADOWS
layout (max_vertices = 102) out;
out vec3 Fcolor;
#else
layout (max_vertices = 144) out;
#endif


in vec4 color[3];
in vec2 texcoord[3];
in vec3 worldPos[3];
flat in vec3 worldNormal[3];

#ifdef TRANSLUCENT_COLORED_SHADOWS
#endif
out vec2 Ftexcoord;

flat out int render;

//#include "/lib/lpv_common.glsl"
#include "/lib/cube/emit.glsl"
#include "/lib/cube/lightData.glsl"

uniform usampler1D texCloseLights;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

void main() {
	for (int i = 0; i < 9; i++) {
		uint data = texelFetch(texCloseLights, i, 0).r;
		float dist;
		ivec3 pos;
		uint id;
		if (getLightData(data, dist, pos, id)) {
			vec3 lightPos = -fract(previousCameraPosition) + (previousCameraPosition - cameraPosition) + vec3(pos) - 14.5;
			if (all(lessThan(vec3(length(worldPos[0] - lightPos), length(worldPos[1] - lightPos), length(worldPos[2] - lightPos)), vec3(14))) && dot(worldNormal[0], worldPos[0] - lightPos) < 0) {
				for (int f = 0; f < 6; f++) {
					render = i + f * 16;
					emitCubemap(directionMatices[f], cubeFaceOffsets[f]*2+renderOffsets[i]*2, lightPos);
				}
			}
		}
	}
	
	render = -1;
	for (int i = 0; i < 3; i++) {
		gl_Position = gl_in[i].gl_Position;
		gl_Position.xy = gl_Position.xy * 0.8 - 0.2 * gl_Position.w;
		Ftexcoord = texcoord[i].xy;
		#ifdef TRANSLUCENT_COLORED_SHADOWS
			Fcolor = color[i].rgb;
		#endif
		EmitVertex();
	}
	EndPrimitive();
}
