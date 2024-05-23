#define RENDER_SHADOWCOMP

layout (local_size_x = 4, local_size_y = 4, local_size_z = 2) in;

const ivec3 workGroups = ivec3(1, 1, 1);

#ifdef IS_LPV_ENABLED
	#ifdef LPV_SHADOWS
		layout(r32ui) restrict uniform uimage3D imgSortLights;
	#endif
#endif

void main() {
	#ifdef IS_LPV_ENABLED
		#ifdef LPV_SHADOWS
			// total coverage of 32x1
			
			uint[9] allData;
			for(int i = 0; i < 9; i++) {
				allData[i] = 4294967295u;
			}

			for (int y = 0; y < 32; y++) {
				for (int z = 0; z < 9; z++) {
					ivec3 pos = ivec3(gl_LocalInvocationIndex, y, z);
					uint data = imageLoad(imgSortLights, pos).r;
					// insert
					for (int i = 0; i < 9; i++) {
						uint minData = min(allData[i], data);
						if (minData == data) data = allData[i];
						allData[i] = minData;
						if (minData == 4294967295u) break;
					}
					/*uint minData = min(allData[z], data);
					if (minData == data) data = allData[z];
					allData[z] = minData;
					if (minData == 4294967295u) break;*/
				}
			}
			for (int i = 0; i < 9; i++) {
				imageStore(imgSortLights, ivec3(gl_LocalInvocationIndex, 0, i), uvec4(allData[i]));
			}
		#endif
	#endif
}
