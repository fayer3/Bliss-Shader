#include "/lib/settings.glsl"

uniform sampler2D colortex7;
uniform sampler2D colortex14;
uniform sampler2D depthtex0;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;

varying vec2 texcoord;
uniform vec2 texelSize;
uniform float frameTimeCounter;
uniform float viewHeight;
uniform float viewWidth;
uniform float aspectRatio;

uniform int hideGUI;

#include "/lib/color_transforms.glsl"
#include "/lib/color_dither.glsl"
#include "/lib/res_params.glsl"


#if DEBUG_VIEW == debug_LIGHTS && defined LPV_SHADOWS
  uniform usampler1D texCloseLights;
  uniform usampler3D texSortLights;
  
  #include "/lib/text.glsl"
  #include "/lib/cube/lightData.glsl"
#endif


float interleaved_gradientNoise(){
	vec2 coord = gl_FragCoord.xy;
	float noise = fract(52.9829189*fract(0.06711056*coord.x + 0.00583715*coord.y));
	return noise;
}

#include "/lib/gameplay_effects.glsl"

void doCameraGridLines(inout vec3 color, vec2 UV){

  float lineThicknessY = 0.001;
  float lineThicknessX = lineThicknessY/aspectRatio;
  
  float horizontalLines = abs(UV.x-0.33);
  horizontalLines = min(abs(UV.x-0.66), horizontalLines);

  float verticalLines = abs(UV.y-0.33);
  verticalLines = min(abs(UV.y-0.66), verticalLines);

  float gridLines = horizontalLines < lineThicknessX || verticalLines < lineThicknessY ? 1.0 : 0.0;

  if(hideGUI > 0.0) gridLines = 0.0;
  color = mix(color, vec3(1.0),  gridLines);
}

uniform vec3 previousCameraPosition;
// uniform vec3 cameraPosition;
uniform mat4 gbufferPreviousModelView;
// uniform mat4 gbufferModelViewInverse;
// uniform mat4 gbufferModelView;

#include "/lib/util.glsl"
#include "/lib/projections.glsl"

vec3 doMotionBlur(vec2 texcoord, float depth, float noise){
  
  float samples = 4.0;
  vec3 color = vec3(0.0);

  float blurMult = 1.0;
  if(depth < 0.56) blurMult = 0.0;

	vec3 viewPos = toScreenSpace(vec3(texcoord, depth));
	viewPos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz + (cameraPosition - previousCameraPosition);

	vec3 previousPosition = mat3(gbufferPreviousModelView) * viewPos + gbufferPreviousModelView[3].xyz;
  previousPosition = toClipSpace3(previousPosition);

	vec2 velocity = texcoord - previousPosition.xy;
  
  // thank you Capt Tatsu for letting me use these
  velocity = (velocity / (1.0 + length(velocity))) * 0.05 * blurMult * MOTION_BLUR_STRENGTH;
  texcoord = texcoord - velocity*(samples*0.5 + noise);
  vec2 screenEdges = 2.0/vec2(viewWidth, viewHeight);

	for (int i = 0; i < int(samples); i++) {

    texcoord += velocity;
    color += texture2D(colortex7, clamp(texcoord, screenEdges, 1.0-screenEdges)).rgb;

  }
  // return vec3(texcoord,0.0);
  return color / samples;
}

uniform sampler2D shadowcolor1;

void main() {
  
  float depth = texture2D(depthtex0,texcoord*RENDER_SCALE).r;
  float noise = interleaved_gradientNoise();

  #ifdef MOTION_BLUR
    vec3 COLOR = doMotionBlur(texcoord, depth, noise);
  #else
    vec3 COLOR = texture2D(colortex7,texcoord).rgb;
  #endif

  #if defined LOW_HEALTH_EFFECT || defined DAMAGE_TAKEN_EFFECT || defined WATER_ON_CAMERA_EFFECT  
    // for making the fun, more fun
    applyGameplayEffects(COLOR, texcoord, noise);
  #endif
  
  #ifdef CAMERA_GRIDLINES
    doCameraGridLines(COLOR, texcoord);
  #endif

  #if DEBUG_VIEW == debug_LIGHTS
    beginText(ivec2(gl_FragCoord.xy * 0.25), ivec2(0, viewHeight*0.25));
    for (int i = 0; i < LPV_SHADOWS_LIGHT_COUNT; i++) {
      uint data = texelFetch(texCloseLights, i, 0).r;
      printString((_L, _i, _g, _h, _t, _space));
      printInt(i);
      float dist;
      ivec3 pos;
      uint id;
      if (!getLightData(data, dist, pos, id)) {
        printString((_colon, _space, _n, _u, _l, _l));
      } else {
        printString((_colon, _space, _d, _colon, _space));
        printFloat(dist);
        printString((_comma, _space, _x, _colon, _space));
        printInt(pos.x - 15);
        printString((_comma, _space, _y, _colon, _space));
        printInt(pos.y - 15);
        printString((_comma, _space, _z, _colon, _space));
        printInt(pos.z - 15);
        printString((_comma, _space, _i, _d, _colon, _space));
        printInt(int(id));
      }
      printLine();
    }
    endText(COLOR);
    
    int curLight = int(frameTimeCounter * 2.0) % LPV_SHADOWS_LIGHT_COUNT;
    ivec3 coords = ivec3((texcoord - vec2(0.75, 0)) * vec2(4.0, 2.0) * textureSize(texSortLights, 0).xy, curLight);
    if(texcoord.x > 0.75 && texcoord.y < 0.5) {
      COLOR.rgb = vec3(texelFetch(texSortLights, coords, 0).rgb / 4294967295.0);
    }
    
    beginText(ivec2(gl_FragCoord.xy * 0.25), ivec2(viewWidth *  0.19, viewHeight * 0.135));
    printString((_L, _i, _g, _h, _t, _colon, _space));
    printInt(curLight);
    endText(COLOR);
    
    vec2 shadowUV = texcoord * vec2(4.0, 2.0);
    if(shadowUV.x < 1.0 && shadowUV.y < 1.0)COLOR = texture2D(shadowcolor1,shadowUV).rgb;
  #endif
  

  #if DEBUG_VIEW == debug_SHADOWMAP

  vec2 shadowUV = texcoord * vec2(2.0, 1.0);

  if(shadowUV.x < 1.0 && shadowUV.y < 1.0 && hideGUI == 1)COLOR = texture2D(shadowcolor1,shadowUV).rgb;
  #endif


  gl_FragColor.rgb = COLOR;
}
