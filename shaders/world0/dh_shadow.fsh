#version 120
//#extension GL_ARB_shader_texture_lod : disable

#include "/lib/settings.glsl"

flat varying int water;
varying vec3 color;

varying float overdrawCull;

uniform sampler2D tex;

#ifdef LPV_SHADOWS
	#include "/lib/cube/cubeData.glsl"
#endif
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {

    if(water > 0){   
        discard;
        return;
    }
    
    if(overdrawCull < 1.0){   
        discard;
        return;
    }
    
    #ifdef LPV_SHADOWS
        if (any(greaterThanEqual(floor(gl_FragCoord.xy), renderBounds[4]))) {
            discard;
            return;
        }
    #endif
    
	gl_FragData[0] = vec4(color, 1.0);
}
