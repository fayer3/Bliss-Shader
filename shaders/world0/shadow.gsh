#version 330 compatibility

layout (triangles) in;
layout (triangle_strip) out;

#include "/lib/settings.glsl"

#if defined LPV_SHADOWS && defined IS_LPV_ENABLED && defined LPV_ENABLED
	#ifdef TRANSLUCENT_COLORED_SHADOWS
	// colored shadows need more vertex data, so can only push fewer vertices
	layout (max_vertices = 102) out;
	out vec3 Fcolor;
	#else
	layout (max_vertices = 144) out;
	#endif
#else
	layout (max_vertices = 3) out;
	out vec3 Fcolor;
#endif

in vec4 color[3];
in vec2 texcoord[3];

out vec2 Ftexcoord;

#if defined LPV_SHADOWS && defined IS_LPV_ENABLED && defined LPV_ENABLED
	in vec3 worldPos[3];
	flat in vec3 worldNormal[3];
	flat out int render;

	#include "/lib/cube/emit.glsl"
	#include "/lib/cube/lightData.glsl"

	uniform usampler1D texCloseLights;
	uniform vec3 cameraPosition;
	uniform vec3 previousCameraPosition;
#endif




void main() {
	#if defined LPV_SHADOWS && defined IS_LPV_ENABLED && defined LPV_ENABLED
		for (int i = 0; i < 9; i++) {
			uint data = texelFetch(texCloseLights, i, 0).r;
			float dist;
			ivec3 pos;
			uint id;
			if (getLightData(data, dist, pos, id)) {
				vec3 lightPos = -fract(previousCameraPosition) + (previousCameraPosition - cameraPosition) + vec3(pos) - 14.5;
				
				vec3 dists = vec3(length(worldPos[0] - lightPos), length(worldPos[1] - lightPos), length(worldPos[2] - lightPos));
				if (
					// check that all vertices are in range, don't want to render unnecessary vertices
					all(lessThan(dists, vec3(14))) &&
					// discard backfaces, if they are closer than 1 block, since those can be the faces from the light
					(max(max(dists.x, dists.y), dists.z) > 1.45 || dot(worldNormal[0], worldPos[0] - lightPos) < 0)) {
					for (int f = 0; f < 6; f++) {
						render = i + f * 16;
						emitCubemap(directionMatices[f], cubeFaceOffsets[f]*2+renderOffsets[i]*2, lightPos);
					}
				}
			}
		}
		
		render = -1;
	#endif

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
