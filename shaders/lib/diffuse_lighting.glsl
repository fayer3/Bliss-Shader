#ifdef IS_LPV_ENABLED
    vec3 GetHandLight(const in int itemId, const in vec3 playerPos, const in vec3 normal) {
        vec3 lightFinal = vec3(0.0);
        vec3 lightColor = vec3(0.0);
        float lightRange = 0.0;

        uvec2 blockData = texelFetch(texBlockData, itemId, 0).rg;
        vec4 lightColorRange = unpackUnorm4x8(blockData.r);
        lightColor = srgbToLinear(lightColorRange.rgb);
        lightRange = lightColorRange.a * 255.0;

        if (lightRange > 0.0) {
            float lightDist = length(playerPos);
            vec3 lightDir = playerPos / lightDist;
            float NoL = 1.0;//max(dot(normal, lightDir), 0.0);
            float falloff = pow(1.0 - lightDist / lightRange, 3.0);
            lightFinal = lightColor * NoL * max(falloff, 0.0);
        }

        return lightFinal;
    }
    
	#ifdef LPV_SHADOWS
        #include "/lib/cube/cubeData.glsl"
        #include "/lib/cube/lightData.glsl"

        uniform usampler1D texCloseLights;
        
        vec3 worldToCube(vec3 worldPos, out int faceIndex) {
            vec3 worldPosAbs = abs(worldPos);
            /*
                cubeBack, 0
                cubeTop, 1
                cubeDown, 2
                cubeLeft, 3
                cubeForward, 4
                cubeRight 5
            */
            if (worldPosAbs.z >= worldPosAbs.x && worldPosAbs.z >= worldPosAbs.y) {
                // looking in z direction (forward | back)
                faceIndex = worldPos.z <= 0.0 ? 0 : 4;
            }
            else if (worldPosAbs.y >= worldPosAbs.x) {
                // looking in y direction (up | down)
                faceIndex = worldPos.y <= 0.0 ? 2 : 1;
            }
            else {
                // looking in x direction (left | right)
                faceIndex = worldPos.x <= 0.0 ? 5 : 3;
            }
            vec4 coord = cubeProjection * directionMatices[faceIndex] * vec4(worldPos, 1.0);
            coord.xyz /= coord.w;
            return coord.xyz * 0.5 + 0.5;
        }

        vec2 cubeOffset(vec2 relativeCoord, int faceIndex, int cube) {
            return relativeCoord*cubeTileRelativeResolution + cubeFaceOffsets[faceIndex] + renderOffsets[cube];
        }

        vec3 getCubeShadow(vec3 cubeShadowPos, int faceIndex, int cube) {
            vec3 pos = vec3(cubeOffset(cubeShadowPos.xy, faceIndex, cube), cubeShadowPos.z);
            float solid = texture(shadowtex0, pos);
            #ifdef LPV_COLOR_SHADOWS
                float noTrans = texture(shadowtex1, pos);
                return noTrans > solid ? texture(shadowcolor0, pos.xy).rgb : vec3(solid);
            #else
                return vec3(solid);
            #endif
        }
    #endif
#endif

vec3 DoAmbientLightColor(
    vec3 playerPos,
    vec3 lpvPos,
    vec3 SkyColor,
    vec3 MinimumColor,
    vec3 TorchColor, 
    vec2 Lightmap,
    float Exposure,
    vec3 normalWorld
){
	// Lightmap = vec2(0.0,1.0);

    float LightLevelZero = clamp(pow(eyeBrightnessSmooth.y/240. + Lightmap.y,2.0) ,0.0,1.0);

    // do sky lighting.
    float skyLM = (pow(Lightmap.y,15.0)*2.0 + pow(Lightmap.y,2.5))*0.5;
    vec3 MinimumLight = MinimumColor * (MIN_LIGHT_AMOUNT*0.01 + nightVision);
    vec3 IndirectLight = max(SkyColor * ambient_brightness * skyLM * 0.7,     MinimumLight); 
    
    // do torch lighting
    float TorchLM = pow(1.0-sqrt(1.0-clamp(Lightmap.x,0.0,1.0)),2.0) * 2.0;
    float TorchBrightness_autoAdjust = mix(1.0, 30.0,  clamp(exp(-10.0*Exposure),0.0,1.0)) ;
    vec3 TorchLight = TorchColor * TorchLM * TORCH_AMOUNT  ;
    
    #if defined IS_LPV_ENABLED && defined MC_GL_EXT_shader_image_load_store
        vec4 lpvSample = SampleLpvLinear(lpvPos);
        vec3 LpvTorchLight = GetLpvBlockLight(lpvSample);

        // i gotchu
        float fadeLength = 10.0; // in blocks
        vec3 cubicRadius = clamp( min(((LpvSize3-1.0) - lpvPos)/fadeLength,      lpvPos/fadeLength) ,0.0,1.0);
        float LpvFadeF = cubicRadius.x*cubicRadius.y*cubicRadius.z;

        LpvFadeF = 1.0 - pow(1.0-pow(LpvFadeF,1.5),3.0); // make it nice and soft :)
        
        TorchLight = mix(TorchLight,LpvTorchLight/5.0,   LpvFadeF);

        const vec3 normal = vec3(0.0); // TODO

        if (heldItemId > 0)
            TorchLight += GetHandLight(heldItemId, playerPos, normal);

        if (heldItemId2 > 0)
            TorchLight += GetHandLight(heldItemId2, playerPos, normal);
        
	    #ifdef LPV_SHADOWS
            for(int i = 0; i < 9; i++){
                uint data = texelFetch(texCloseLights, i, 0).r;
                float dist;
                ivec3 pos;
                uint blockId;
                if (getLightData(data, dist, pos, blockId)) {
                    vec3 lightPos = -fract(previousCameraPosition) - cameraPosition+previousCameraPosition + vec3(pos) - 14.5;
                    int face = 0;
                    vec3 dir = playerPos - lightPos;
                    float d = dot(-normalWorld, dir-0.1);
                    if (d > 0) {
                        uint blockData = texelFetch(texBlockData, int(blockId), 0).r;
                        vec4 lightColorRange = unpackUnorm4x8(blockData);
                        lightColorRange.a *= 255.0;
                        float dist = length(dir);
                        if (dist < lightColorRange.a) {
                            vec3 pos = worldToCube(dir + normalWorld * 0.05, face);
                            float blend = (1.0 - dist / lightColorRange.a) / (1.0 + dist * -0.3 + dist * dist);
                            TorchLight += d * lightColorRange.rgb * getCubeShadow(pos, face, i) * blend;
                        }
                    }
                } else {
                    // since lights are sorted, if one light is invalid all followings are aswell
                    break;
                }
            }
        #endif
    #endif

    return IndirectLight + TorchLight * TorchBrightness_autoAdjust;
}


// this is dumb, and i plan to remove it eventually...
vec4 RT_AmbientLight(
    vec3 playerPos,
    vec3 lpvPos,
    float Exposure,
    vec2 Lightmap,
    vec3 TorchColor
){
    float skyLM = (pow(Lightmap.y,15.0)*2.0 + pow(Lightmap.y,2.5))*0.5;


    // do torch lighting
    float TorchLM = pow(1.0-sqrt(1.0-clamp(Lightmap.x,0.0,1.0)),2.0) * 2.0;
    float TorchBrightness_autoAdjust = mix(1.0, 30.0,  clamp(exp(-10.0*Exposure),0.0,1.0)) ;
    vec3 TorchLight = TorchColor * TorchLM * TORCH_AMOUNT  ;
    
    #if defined IS_LPV_ENABLED && defined MC_GL_EXT_shader_image_load_store
        vec4 lpvSample = SampleLpvLinear(lpvPos);
        vec3 LpvTorchLight = GetLpvBlockLight(lpvSample);

        // i gotchu
        float fadeLength = 10.0; // in blocks
        vec3 cubicRadius = clamp( min(((LpvSize3-1.0) - lpvPos)/fadeLength,      lpvPos/fadeLength) ,0.0,1.0);
        float LpvFadeF = cubicRadius.x*cubicRadius.y*cubicRadius.z;

        LpvFadeF = 1.0 - pow(1.0-pow(LpvFadeF,1.5),3.0); // make it nice and soft :)
        
        TorchLight = mix(TorchLight,LpvTorchLight/5.0,   LpvFadeF);

        const vec3 normal = vec3(0.0); // TODO

        if (heldItemId > 0)
            TorchLight += GetHandLight(heldItemId, playerPos, normal);

        if (heldItemId2 > 0)
            TorchLight += GetHandLight(heldItemId2, playerPos, normal);
    #endif

    return vec4(TorchLight, skyLM);
}