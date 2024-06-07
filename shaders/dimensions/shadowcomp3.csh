#define RENDER_SHADOWCOMP

layout (local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

const ivec3 workGroups = ivec3(2, 1, 1);

#ifdef IS_LPV_ENABLED
	#ifdef LPV_SHADOWS
		uniform vec3 cameraPosition;
		layout(r32ui) restrict writeonly uniform uimage3D imgSortLights;

		#include "/lib/lpv_common.glsl"
		#include "/lib/lpv_blocks.glsl"
		#include "/lib/voxel_common.glsl"

		uint GetVoxelBlock(const in ivec3 voxelPos) {
			if (clamp(voxelPos, ivec3(0), ivec3(VoxelSize3-1u)) != voxelPos)
				return BLOCK_EMPTY;
			
			return imageLoad(imgVoxelMask, voxelPos).r;
		}
	#endif
#endif

void main() {
	#ifdef IS_LPV_ENABLED
		#ifdef LPV_SHADOWS
			// total coverage of 32x32
			// 8x8 blocks per group, map the 8 z blocks to 2x4, for a total coverage per group of 16x32
			uvec3 chunkPos = gl_WorkGroupID * gl_WorkGroupSize * uvec3(2,1,1);
			uvec2 xyPos = chunkPos.xy + uvec2(8) * uvec2(gl_LocalInvocationID.z / 4, gl_LocalInvocationID.z % 4) + gl_LocalInvocationID.xy;
			
			uint[9] allData;
			for(int i = 0; i < 9; i++) {
				allData[i] = 4294967295u;
			}

			for (int z = 0; z < 32; z++) {
				ivec3 pos = ivec3(xyPos.xy, z) - 16;
				ivec3 posGlob = pos + int(LpvSize / 2);
				uint blockId = GetVoxelBlock(posGlob);
				if (blockId != BLOCK_EMPTY) {
					uint blockData = imageLoad(imgBlockData, int(blockId)).r;
					if (unpackUnorm4x8(blockData.r).a > 0) {
						uvec3 posU = uvec3(pos + 15);
						float dist = min(length(vec3(pos) - fract(cameraPosition)), 15.9);
						if (clamp(posU, uvec3(0), uvec3(31)) == posU) {
							uint data = uint(dist*4) << 26 | posU.x << 21 | posU.y << 16 | posU.z << 11 | blockId;
							for (int i = 0; i < 9; i++) {
								uint minData = min(allData[i], data);
								if (minData == data) data = allData[i];
								allData[i] = minData;
							}
						}
					}
				}
			}
			for (int i = 0; i < 9; i++) {
				imageStore(imgSortLights, ivec3(xyPos.xy, i), uvec4(allData[i]));
			}
		#endif
	#endif
}
