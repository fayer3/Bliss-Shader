#if !defined HAND
	const mat4 cubeProjection = mat4(1.0, 0.0, 0.0, 0.0,
		0.0, 1.0, 0.0, 0.0,
		0.0, 0.0, (1000.0+0.01)/(0.01-1000.0), -1.0,
		0.0, 0.0, (2.0*1000.0*0.01)/(0.01-1000.0), 0.0);
#else
	const mat4 cubeProjection = mat4(1.0, 0.0, 0.0, 0.0,
		0.0, 1.0, 0.0, 0.0,
		0.0, 0.0, (1000.0+0.1)/(0.1-1000.0), -1.0,
		0.0, 0.0, (2.0*1000.0*0.1)/(0.1-1000.0), 0.0);
#endif

const mat4 cubeProjectionInverse = mat4(1.0, 0.0, 0.0, 0.0,
	0.0, 1.0,  0.0, 0.0,
	0.0, 0.0,  0.0, 1.0/((2*1000.0*0.01)/(0.01-1000.0)),
	0.0, 0.0, -1.0, ((1000.0+0.01) / (0.01-1000.0)) / ((2.0*1000.0*0.01) / (0.01-1000.0)));

// LookAt matrix based on https://stackoverflow.com/a/21830596
// eye at 0, because worldspace
// left = -x
// up = +y
// forward = -z
const mat4 cubeForward = mat4(-1.0, 0.0, 0.0, 0.0,
	0.0, 1.0, 0.0, 0.0,
	0.0, 0.0, -1.0, 0.0,
	0.0, 0.0, 0.0, 1.0);
// left = -z
// up = +y
// forward = +x
const mat4 cubeRight = mat4(0.0, 0.0, 1.0, 0.0,
	0.0, 1.0, 0.0, 0.0,
	-1.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 1.0);
// left = +x
// up = +y
// forward = +z
const mat4 cubeBack = mat4(1.0, 0.0, 0.0, 0.0,
	0.0, 1.0, 0.0, 0.0,
	0.0, 0.0, 1.0, 0.0,
	0.0, 0.0, 0.0, 1.0);
// left = +z
// up = +y
// forward = -x
const mat4 cubeLeft = mat4(0.0, 0.0, -1.0, 0.0,
	0.0, 1.0, 0.0, 0.0,
	1.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 1.0);
// left = -x
// up = -z
// forward = -y
const mat4 cubeTop = mat4(-1.0, 0.0, 0.0, 0.0,
	0.0, 0.0, -1.0, 0.0,
	0.0, -1.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 1.0);
// left = -x
// up = z
// forward = +y
const mat4 cubeDown = mat4(-1.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 1.0, 0.0,
	0.0, 1.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 1.0);

mat4 directionMatices[6] = mat4[](
	cubeBack,
	cubeTop,
	cubeDown,
	cubeLeft,
	cubeForward,
	cubeRight);

mat4 directionMaticesInverse[6] = mat4[](
	transpose(cubeBack),
	transpose(cubeTop),
	transpose(cubeDown),
	transpose(cubeLeft),
	transpose(cubeForward),
	transpose(cubeRight));

const vec2 faceOffsets[6] = vec2[](
	vec2(0.0, 0.0),
	vec2(2.0, 0.0),
	vec2(1.0, 1.0),
	vec2(2.0, 1.0),
	vec2(1.0, 0.0),
	vec2(0.0, 1.0)
	);
	
vec2 screenRes = vec2(shadowMapResolution);
vec2 cubeTileResolution = floor(screenRes/(vec2(3.0,2.0)*5.0));
vec2 cubeTileRelativeResolution = cubeTileResolution/screenRes;

ivec2 minBounds[6] = ivec2[](
	ivec2(0, cubeTileResolution.y),
	ivec2(cubeTileResolution.xy),
	ivec2(cubeTileResolution.x*2,cubeTileResolution.y),
	ivec2(0, 0),
	ivec2(cubeTileResolution.x, 0),
	ivec2(cubeTileResolution.x*2, 0));

ivec2 maxBounds[6] = ivec2[](
	ivec2(cubeTileResolution.x, cubeTileResolution.y*2),
	ivec2(cubeTileResolution.x*2, cubeTileResolution.y*2),
	ivec2(cubeTileResolution.x*3, cubeTileResolution.y*2),
	ivec2(cubeTileResolution.x, cubeTileResolution.y),
	ivec2(cubeTileResolution.x*2, cubeTileResolution.y),
	ivec2(cubeTileResolution.x*3, cubeTileResolution.y));

vec2 cubeFaceOffsets[6] = vec2[](
	vec2(0.0, cubeTileRelativeResolution.y),
	vec2(cubeTileRelativeResolution.xy),
	vec2(cubeTileRelativeResolution.x*2.0, cubeTileRelativeResolution.y),
	vec2(0.0, 0.0),
	vec2(cubeTileRelativeResolution.x, 0.0),
	vec2(cubeTileRelativeResolution.x*2.0, 0.0));

vec2 renderOffsets[9] = vec2[](
	vec2(0.0, cubeTileRelativeResolution.y*8.0),
	vec2(cubeTileRelativeResolution.x*3.0, cubeTileRelativeResolution.y*8.0),
	vec2(cubeTileRelativeResolution.x*6.0, cubeTileRelativeResolution.y*8.0),
	vec2(cubeTileRelativeResolution.x*9.0, cubeTileRelativeResolution.y*8.0),
	vec2(cubeTileRelativeResolution.x*12.0, cubeTileRelativeResolution.y*8.0),
	vec2(cubeTileRelativeResolution.x*12.0, cubeTileRelativeResolution.y*6.0),
	vec2(cubeTileRelativeResolution.x*12.0, cubeTileRelativeResolution.y*4.0),
	vec2(cubeTileRelativeResolution.x*12.0, cubeTileRelativeResolution.y*2.0),
	vec2(cubeTileRelativeResolution.x*12.0, 0.0));
vec2 renderBounds[9] = vec2[](
	vec2(0.0, cubeTileResolution.y*8.0),
	vec2(cubeTileResolution.x*3.0, cubeTileResolution.y*8.0),
	vec2(cubeTileResolution.x*6.0, cubeTileResolution.y*8.0),
	vec2(cubeTileResolution.x*9.0, cubeTileResolution.y*8.0),
	vec2(cubeTileResolution.x*12.0, cubeTileResolution.y*8.0),
	vec2(cubeTileResolution.x*12.0, cubeTileResolution.y*6.0),
	vec2(cubeTileResolution.x*12.0, cubeTileResolution.y*4.0),
	vec2(cubeTileResolution.x*12.0, cubeTileResolution.y*2.0),
	vec2(cubeTileResolution.x*12.0, 0.0));

vec2 cornerOffset = vec2(-1.0 + cubeTileRelativeResolution);