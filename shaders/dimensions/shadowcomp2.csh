#define RENDER_SHADOWCOMP

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

const ivec3 workGroups = ivec3(1, 1, 1);

#ifdef IS_LPV_ENABLED
	uniform vec3 cameraPosition;
	layout(r32ui) uniform uimage1D imgCloseLights;

	#include "/lib/lpv_common.glsl"
	#include "/lib/lpv_blocks.glsl"
	#include "/lib/voxel_common.glsl"

	uint GetVoxelBlock(const in ivec3 voxelPos) {
		if (clamp(voxelPos, ivec3(0), ivec3(VoxelSize3-1u)) != voxelPos)
			return BLOCK_EMPTY;
		
		return imageLoad(imgVoxelMask, voxelPos).r;
	}

	void addLight(in ivec3 pos, int range, uint id){
		float d = length(vec3(pos) - fract(cameraPosition));
		// only store lights
		if (d < 16.0 && range > 0) {
			uvec3 posU = uvec3(pos + 15);
			uint data = uint(d*4) << 26 | posU.x << 21 | posU.y << 16 | posU.z << 11 | id;
			uint prevData = data;
			for (int i = 0; i < 9; i++) {
				prevData = imageAtomicMin(imgCloseLights, i, data);
				if (prevData > data) data = prevData;
			}
		}
	}
#endif

////////////////////////////// VOID MAIN //////////////////////////////

void main() {
	#ifdef IS_LPV_ENABLED
		for (int i = 0; i < 10; i++) {
			imageStore(imgCloseLights, i, uvec4(4294967295u));
		}

		for (int x = 0; x < 32; x++) {
			for (int y = 0; y < 32; y++) {
				for (int z = 0; z < 32; z++) {
					ivec3 pos = ivec3(x,y,z) - 16;
					ivec3 posGlob = pos + int(LpvSize / 2);
					uint blockId = GetVoxelBlock(posGlob);
					uint blockData = imageLoad(imgBlockData, int(blockId)).r;
					int lightRange = int(unpackUnorm4x8(blockData.r).a * 255.0);
					addLight(pos, lightRange, blockId);
				}
			}
		}
	#endif
}
