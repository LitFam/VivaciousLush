/*=============================================================================
                                                           
 d8b 888b     d888 888b     d888 8888888888 8888888b.   .d8888b.  8888888888 
 Y8P 8888b   d8888 8888b   d8888 888        888   Y88b d88P  Y88b 888        
     88888b.d88888 88888b.d88888 888        888    888 Y88b.      888        
 888 888Y88888P888 888Y88888P888 8888888    888   d88P  "Y888b.   8888888    
 888 888 Y888P 888 888 Y888P 888 888        8888888P"      "Y88b. 888        
 888 888  Y8P  888 888  Y8P  888 888        888 T88b         "888 888        
 888 888   "   888 888   "   888 888        888  T88b  Y88b  d88P 888        
 888 888       888 888       888 8888888888 888   T88b  "Y8888P"  8888888888                                                                 
                                                                            
    Copyright (c) Pascal Gilcher. All rights reserved.
    
    * Unauthorized copying of this file, via any medium is strictly prohibited
 	* Proprietary and confidential

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

===============================================================================

    RTGI 0.41

    Author:         Pascal Gilcher

    More info:      https://martysmods.com
                    https://patreon.com/mcflypg
                    https://github.com/martymcmodding  	

=============================================================================*/

/*=============================================================================
	Preprocessor settings
=============================================================================*/

#ifndef ENABLE_INFINITE_BOUNCES
 #define ENABLE_INFINITE_BOUNCES       0   //[0 or 1]      If enabled, path tracer samples previous frame GI as well, causing a feedback loop to simulate secondary bounces, causing a more widespread GI.
#endif

#ifndef ENABLE_IMAGE_BASED_LIGHTING
 #define ENABLE_IMAGE_BASED_LIGHTING   0   //[0 to 3]      0: no ibl infill | 1: use ibl infill
#endif

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform float RT_SAMPLE_RADIUS <
	ui_type = "drag";
	ui_min = 0.5; ui_max = 20.0;
    ui_step = 0.01;
    ui_label = "Ray Length";
	ui_tooltip = "Maximum ray length, directly affects\nthe spread radius of shadows / bounce lighting";
    ui_category = "Ray Tracing";
> = 8.0;

uniform int RT_RAY_AMOUNT <
	ui_type = "slider";
	ui_min = 1; ui_max = 20;
    ui_label = "Amount of Rays";
    ui_tooltip = "Amount of rays launched per pixel in order to\nestimate the global illumination at this location.\nMore rays result in less noisy lighting at the cost of performance.";
    ui_category = "Ray Tracing";
> = 4;

uniform int RT_RAY_STEPS <
	ui_type = "slider";
	ui_min = 1; ui_max = 40;
    ui_label = "Amount of Steps per Ray";
    ui_tooltip = "RTGI performs step-wise raymarching to check for ray hits.\nFewer steps may result in rays skipping over small details. Higher settings cost more performance.";
    ui_category = "Ray Tracing";
> = 20;

uniform float RT_Z_THICKNESS <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 4.0;
    ui_step = 0.01;
    ui_label = "Z Thickness";
	ui_tooltip = "The shader can't know how thick objects are, since it only\nsees the side the camera faces and has to assume a fixed value.\n\nUse this parameter to remove halos around thin objects.";
    ui_category = "Ray Tracing";
> = 0.75;

uniform bool RT_HIGHP_LIGHT_SPREAD <
    ui_label = "Enable precise light spreading";
    ui_tooltip = "Rays accept scene intersections within a small error margin.\nEnabling this will snap rays to the actual hit location.\nThis results in sharper but more realistic lighting.";
    ui_category = "Ray Tracing";
> = true;

uniform float RT_AO_AMOUNT <
	ui_type = "drag";
	ui_min = 0; ui_max = 10.0;
    ui_step = 0.01;
    ui_label = "Ambient Occlusion Intensity";
    ui_category = "Blending";
> = 8.0;

uniform float RT_IL_AMOUNT <
	ui_type = "drag";
	ui_min = 0; ui_max = 10.0;
    ui_step = 0.01;
    ui_label = "Bounce Lighting Intensity";
    ui_category = "Blending";
> = 8.0;

#if ENABLE_INFINITE_BOUNCES
uniform float RT_IL_BOUNCE_WEIGHT <
    ui_type = "drag";
    ui_min = 0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Next Bounce Weight";
    ui_category = "Blending";
> = 0.0;
#endif

#if ENABLE_IMAGE_BASED_LIGHTING
uniform float RT_IBL_AMOUNT <
    ui_type = "drag";
    ui_min = 0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Image Based Lighting Intensity";
    ui_category = "Blending";
> = 0.35;
#else 
 #define RT_IBL_AMOUNT 0.0
#endif

uniform float RT_FADE_DEPTH <
	ui_type = "drag";
    ui_label = "Fade Out Range";
	ui_min = 0.001; ui_max = 1.0;
	ui_tooltip = "Distance falloff, higher values increase RTGI draw distance.";
    ui_category = "Blending";
> = 0.3;

uniform bool ASSUME_SRGB_INPUT <
    ui_label = "Assume sRGB input";
    ui_tooltip = "Converts color to linear before converting to HDR.\nDepending on the game color format, this can improve light behavior and blending.";
    ui_category = "Experimental";
> = true;

uniform bool OLD_BLENDING_MATH <
    ui_label = "Use old blending math";
    ui_tooltip = "reverts the lighting mode to the older, incorrect blending mode which some users prefer.";
> = false;

uniform int RT_DEBUG_VIEW <
	ui_type = "combo";
    ui_label = "Enable Debug View";
	ui_items = "None\0Lighting Channel\0 3-Way Split\0";
	ui_tooltip = "Different debug outputs";
    ui_category = "Debug";
> = 0;

uniform int UIHELP <
	ui_type = "radio";
	ui_label = " ";	
	ui_text ="\nDescription for preprocessor definitions:\n"
	"\n"
	"ENABLE_INFINITE_BOUNCES\n"
	"\n"
	"Simulates additional light interactions with the scene,\n"
    "allowing light to spread further into dark corners.    \n"
	"0: off\n"
	"1: on\n"	
	"\n"
	"ENABLE_IMAGE_BASED_LIGHTING\n"
	"\n"
	"Computes coarse lighting to use as a fallback when a ray\n"
	"did not hit anything. Produces more rounded lighting.\n"
	"0: off\n"
	"1: on\n";
	ui_category_closed = false;
>;

/*
uniform float4 tempF1 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);

uniform float4 tempF2 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);

uniform float4 tempF3 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);

uniform float4 tempF4 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);

uniform float4 tempF5 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);
*/
/*=============================================================================
	Textures, Samplers, Globals, Structs
=============================================================================*/

//do NOT change anything here. "hurr durr I changed this and now it works"
//you ARE breaking things down the line, if the shader does not work without changes
//here, it's by design.

uniform uint  FRAMECOUNT  < source = "framecount"; >;
uniform float FRAMETIME   < source = "frametime";  >;

texture ColorInputTex : COLOR;
texture DepthInputTex : DEPTH;
sampler ColorInput 	{ Texture = ColorInputTex; };
sampler DepthInput  { Texture = DepthInputTex; };

#include ".\MartysMods\mmx_global.fxh"
#include ".\MartysMods\mmx_depth.fxh"
#include ".\MartysMods\mmx_math.fxh"
#include ".\MartysMods\mmx_qmc.fxh"
#include ".\MartysMods\mmx_deferred.fxh"
#include ".\MartysMods\mmx_camera.fxh"
#include ".\MartysMods\mmx_sampling.fxh"

//#undef _COMPUTE_SUPPORTED
//#define DEBUG_DISABLE_FILTER

//log2 macro for uints up to 16 bit, inefficient in runtime but preprocessor doesn't care
#define T1(x,n) ((uint(x)>>(n))>0)
#define T2(x,n) (T1(x,n)+T1(x,n+1))
#define T4(x,n) (T2(x,n)+T2(x,n+2))
#define T8(x,n) (T4(x,n)+T4(x,n+4))
#define LOG2(x) (T8(x,0)+T8(x,8))

#define CEIL_DIV(num, denom) ((((num) - 1) / (denom)) + 1)

texture RadianceTex                     { Width = BUFFER_WIDTH/6;   Height = BUFFER_HEIGHT/6; Format = RGBA16F; };
texture GBufferTexPrev                  { Width = BUFFER_WIDTH;     Height = BUFFER_HEIGHT;   Format = RGBA16F; };

texture GITex                           { Width = BUFFER_WIDTH;         Height = BUFFER_HEIGHT;     Format = RGBA16F;   MipLevels = 4;  };
texture GITexPrev                       { Width = BUFFER_WIDTH;         Height = BUFFER_HEIGHT;     Format = RGBA16F;   MipLevels = 4;  };
texture GIFilterTemp                    { Width = BUFFER_WIDTH;         Height = BUFFER_HEIGHT;     Format = RGBA16F;   MipLevels = 4;  };
texture GIFilterTemp2                   { Width = BUFFER_WIDTH;         Height = BUFFER_HEIGHT;     Format = RGBA16F;   MipLevels = 4;  };

sampler sRadianceTex                    { Texture = RadianceTex; };
sampler sGBufferTexPrev	                { Texture = GBufferTexPrev; };
sampler sGITex	                        { Texture = GITex;          };
sampler sGITexPrev	                    { Texture = GITexPrev;      };
sampler sGIFilterTemp	                { Texture = GIFilterTemp;   };
sampler sGIFilterTemp2	                { Texture = GIFilterTemp2;  };

texture JitterTexSTBN                    < source = "stbn128_128_4.png"; > { Width = 256; Height = 256; Format = RGBA8; };
sampler	sJitterTexSTBN                  { Texture = JitterTexSTBN; AddressU = WRAP; AddressV = WRAP; };

//xy luma moments, z = stack size, w = 1
texture HistoryLengthAndVarianceTex                 { Width = BUFFER_WIDTH;         Height = BUFFER_HEIGHT;     Format = RGBA16F;          MipLevels = 4; };
texture HistoryLengthAndVarianceTexPrev             { Width = BUFFER_WIDTH;         Height = BUFFER_HEIGHT;     Format = RGBA16F;          MipLevels = 4; };
sampler sHistoryLengthAndVarianceTex	            { Texture = HistoryLengthAndVarianceTex; };
sampler sHistoryLengthAndVarianceTexPrev	        { Texture = HistoryLengthAndVarianceTexPrev; };

#define PROBE_VOLUME_RES 32
#if ENABLE_IMAGE_BASED_LIGHTING
texture SHProbeTex      			        { Width = PROBE_VOLUME_RES*PROBE_VOLUME_RES;   Height = PROBE_VOLUME_RES*3;  Format = RGBA32F;};
texture SHProbeTexPrev      		        { Width = PROBE_VOLUME_RES*PROBE_VOLUME_RES;   Height = PROBE_VOLUME_RES*3;  Format = RGBA32F;};
sampler sSHProbeTex	    		            { Texture = SHProbeTex;	    };
sampler sSHProbeTexPrev	    	            { Texture = SHProbeTexPrev;	};
#else //just define valid texture handles so we can leave the functions etc. uncommented
 #define SHProbeTex ColorInputTex
 #define SHProbeTexPrev ColorInputTex
 #define sSHProbeTex ColorInput
 #define sSHProbeTexPrev ColorInput
#endif 

#if _COMPUTE_SUPPORTED
texture ZSrc                    { Width = BUFFER_WIDTH;     Height = BUFFER_HEIGHT;   Format = R16F;    };
sampler sZSrc                   { Texture = ZSrc; MinFilter=POINT; MipFilter=POINT; MagFilter=POINT;};
storage stZSrc                  { Texture = ZSrc;             };
storage stGITex                 { Texture = GITex;          };
storage stGITexPrev             { Texture = GITexPrev;      };
#define DEINT_TILES             uint2(4, 4)
#define ZTexture                sZSrc
#else 
texture ZSrcLo                  { Width = BUFFER_WIDTH/2;     Height = BUFFER_HEIGHT/2;   Format = R16F;    };
sampler sZSrcLo                 { Texture = ZSrcLo; MinFilter=POINT; MipFilter=POINT; MagFilter=POINT;};
#define ZTexture                sZSrcLo
#define DEINT_TILES             uint2(1, 1) //dummy so the rest compiles, can't be arsed to wrap it all in preproc
#endif

struct VSOUT
{
    float4 vpos : SV_Position;
    float2 uv   : TEXCOORD0;
};

struct CSIN 
{
    uint3 groupthreadid     : SV_GroupThreadID;         
    uint3 groupid           : SV_GroupID;            
    uint3 dispatchthreadid  : SV_DispatchThreadID;     
    uint threadid           : SV_GroupIndex;
};

/*=============================================================================
	Functions
=============================================================================*/

float2 pixel_idx_to_uv(uint2 pos, float2 texture_size)
{
    float2 inv_texture_size = rcp(texture_size);
    return pos * inv_texture_size + 0.5 * inv_texture_size;
}

bool check_boundaries(uint2 pos, uint2 dest_size)
{
    return all(pos < dest_size) && all(pos >= uint2(0, 0));
}

uint2 deinterleave_pos(uint2 pos, uint2 tiles, uint2 gridsize)
{
    int2 blocksize = CEIL_DIV(gridsize, tiles); 
    int2 block_id     = pos % tiles;
    int2 pos_in_block = pos / tiles;
    return block_id * blocksize + pos_in_block;
}

uint2 reinterleave_pos(uint2 pos, uint2 tiles, uint2 gridsize)
{
    int2 blocksize = CEIL_DIV(gridsize, tiles); 
    int2 block_id     = pos / blocksize;  
    int2 pos_in_block = pos % blocksize;
    return pos_in_block * tiles + block_id;
}

float3 srgb_to_acescg(float3 srgb)
{
    float3x3 m = float3x3(  0.613097, 0.339523, 0.047379,
                            0.070194, 0.916354, 0.013452,
                            0.020616, 0.109570, 0.869815);
    return mul(m, srgb);           
}

float3 acescg_to_srgb(float3 acescg)
{     
    float3x3 m = float3x3(  1.704859, -0.621715, -0.083299,
                            -0.130078,  1.140734, -0.010560,
                            -0.023964, -0.128975,  1.153013);                 
    return mul(m, acescg);            
}

float3 cone_overlap(float3 c)
{
    float k = 0.7 * 0.33;
    float2 f = float2(1 - 2 * k, k);
    float3x3 m = float3x3(f.xyy, f.yxy, f.yyx);
    return mul(c, m);
}

float3 cone_overlap_inv(float3 c)
{
    float k = 0.7 * 0.33;
    float2 f = float2(k - 1, k) * rcp(3 * k - 1);
    float3x3 m = float3x3(f.xyy, f.yxy, f.yyx);
    return mul(c, m);
}

float3 unpack_hdr(float3 color)
{
    color  = saturate(color);   
    if(ASSUME_SRGB_INPUT) color = color*0.283799*((2.52405+color)*color);    
    color = srgb_to_acescg(color);
    color = color * rcp(1.04 - saturate(color));    
    return color;
}

float3 pack_hdr(float3 color)
{
    color =  1.04 * color * rcp(color + 1.0);   
    color = acescg_to_srgb(color);    
    color  = saturate(color);   
    if(ASSUME_SRGB_INPUT) color = 1.14374*(-0.126893*color+sqrt(color));
    return color;     
}

float3 linear_to_ycocg(float3 color)
{
    float Y  = dot(color, float3(0.25, 0.5, 0.25));
    float Co = dot(color, float3(0.5, 0.0, -0.5));
    float Cg = dot(color, float3(-0.25, 0.5, -0.25));
    return float3(Y, Co, Cg);
}

float3 ycocg_to_linear(float3 color)
{
    float t = color.x - color.z;
    float3 r;
    r.y = color.x + color.z;
    r.x = t + color.y;
    r.z = t - color.y;
    return max(r, 0.0);
}

//Co Cg Y Y^2
float4 encode_hdr_to_filter(float3 color)
{
    color = acescg_to_srgb(color);
    color = linear_to_ycocg(color);
    return float4(color.gbr, color.r * color.r);
}

float3 decode_hdr_from_filter(float3 color)
{
    float3 res = color.brg;
    res = ycocg_to_linear(res);
    res = srgb_to_acescg(res);
    return res;
}

float3 get_jitter_stbn_4(uint2 texelpos, uint framecount)
{
    const uint dim_xy = 128;
    const uint dim_z = 4; 
    const uint dim_z_sqrt = 2;

    uint2 texel_in_tile = texelpos % dim_xy;
    uint frame = framecount % dim_z;
    uint2 tile;  
    tile.x = frame % dim_z_sqrt;
    tile.y = frame / dim_z_sqrt;

    uint2 texturepos = tile * dim_xy + texel_in_tile;
    float3 jitter = tex2Dfetch(sJitterTexSTBN, texturepos).xyz;
    jitter = frac(jitter + tex2Dfetch(sJitterTexSTBN, texturepos / dim_xy).xyz);
    return jitter;
}

float4 get_gbuffer(float2 uv)
{
    return float4(Deferred::get_normals(uv), Camera::depth_to_z(Depth::get_linear_depth(uv)));
}

float4 get_gbuffer_prev(float2 uv)
{
    return tex2Dlod(sGBufferTexPrev, uv, 0);
}

float get_fade_factor(float depth)
{
    float fade = saturate(1 - depth * depth); //fixed fade that smoothly goes to 0 at depth = 1
    depth /= RT_FADE_DEPTH;
    fade *= saturate(depth * 1024.0);
    return fade * saturate(exp2(-depth * depth)); //overlaying regular exponential fade
}

struct TraceContext
{
    float4 uv;
    uint4 texel; //xy: working pos, zw: write pos
    uint2 tile;
    float3 pos; //view space position
    float3 normal;
    float3 viewdir;
};

TraceContext init(in uint2 working_pos, in uint2 working_size)
{
    const uint2 tile_size = CEIL_DIV(working_size, DEINT_TILES);

    TraceContext o;   
    o.texel.xy = working_pos;
    o.texel.zw = reinterleave_pos(o.texel.xy, DEINT_TILES, working_size);
    o.tile = o.texel.xy / tile_size;
    o.uv.xy = pixel_idx_to_uv(o.texel.xy, working_size); 
    o.uv.zw = pixel_idx_to_uv(o.texel.zw, working_size); 

    float depth = Depth::get_linear_depth(o.uv.zw);

    o.pos = Camera::uv_to_proj(o.uv.zw, Camera::depth_to_z(depth));
    o.normal = Deferred::get_normals(o.uv.zw);
    o.viewdir = normalize(o.pos);

    o.pos *= 0.996; //bias 
   // o.pos += o.normal * depth;

    return o;
}

float3 screen_to_probe(float3 uvw){uvw.z = pow(abs(uvw.z) * 2.0, 0.5);return uvw;}
float3 probe_to_screen(float3 uvw){uvw.z = pow(abs(uvw.z), 2.0) * 0.5;return uvw;}

float3 eval_probe(TraceContext _this, float3 jitter)
{
    float3 uvw = float3(_this.uv.zw, Camera::z_to_depth(_this.pos.z));
    uvw += (jitter - 0.5) / PROBE_VOLUME_RES * 2.8; //jitter to avoid artifacts
    uvw = screen_to_probe(uvw);

    float4 sh_r = Sampling::sample_volume_trilinear(sSHProbeTex, uvw, PROBE_VOLUME_RES, 0);
    float4 sh_g = Sampling::sample_volume_trilinear(sSHProbeTex, uvw, PROBE_VOLUME_RES, 1);
    float4 sh_b = Sampling::sample_volume_trilinear(sSHProbeTex, uvw, PROBE_VOLUME_RES, 2);

    float4 sh_coeffs = float4(0.282094791, 0.4886025119, -0.4886025119, -0.4886025119);
    float4 sh_normal = sh_coeffs * float4(1, _this.normal.zyx);
    float3 irradiance = float3(dot(sh_normal, sh_r), dot(sh_normal, sh_g), dot(sh_normal, sh_b));
    irradiance = max(0, irradiance);
    return irradiance; 
}

/*=============================================================================
	Shader Entry Points
=============================================================================*/

VSOUT MainVS(in uint id : SV_VertexID)
{
    VSOUT o;
    FullscreenTriangleVS(id, o.vpos, o.uv); 
    return o;
}

void AlbedoInputPS(in VSOUT i, out float4 o : SV_Target0)
{        
    o = 0;    
    [unroll]for(int x = -2; x <= 2; x++)
    [unroll]for(int y = -2; y <= 2; y++)
    {
        float2 tuv = i.uv + BUFFER_PIXEL_SIZE * 2 * float2(x, y);       
        float3 color = tex2D(ColorInput, tuv).rgb;
#if ENABLE_INFINITE_BOUNCES 
        float3 lighting = decode_hdr_from_filter(tex2D(sGIFilterTemp, tuv).rgb);
        lighting = lerp(lighting, dot(lighting, 0.333), 0.5);
        color = unpack_hdr(color);
        color = lerp(color, color * lighting * 0.25, RT_IL_BOUNCE_WEIGHT * RT_IL_BOUNCE_WEIGHT * RT_IL_BOUNCE_WEIGHT);
        color = pack_hdr(color);
#endif
        o += color;
    }        
    o /= 25.0;     
    o.rgb = unpack_hdr(o.rgb);
    o.a = Depth::get_linear_depth(i.uv) < 0.999; //sky
}

#if _COMPUTE_SUPPORTED
void DepthInterleaveCS(in CSIN i)
{
    if(!check_boundaries(i.dispatchthreadid.xy * 2, BUFFER_SCREEN_SIZE)) return;

    float2 uv = pixel_idx_to_uv(i.dispatchthreadid.xy * 2, BUFFER_SCREEN_SIZE);
    float2 corrected_uv = Depth::correct_uv(uv); //fixed for lookup 

#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
    corrected_uv.y -= BUFFER_PIXEL_SIZE.y * 0.5;    //shift upwards since gather looks down and right
    float4 depth_texels = tex2DgatherR(DepthInput, corrected_uv).wzyx;  
#else
    float4 depth_texels = tex2DgatherR(DepthInput, corrected_uv);
#endif

    depth_texels = Depth::linearize(depth_texels);
    depth_texels.x = Camera::depth_to_z(depth_texels.x);
    depth_texels.y = Camera::depth_to_z(depth_texels.y);
    depth_texels.z = Camera::depth_to_z(depth_texels.z);
    depth_texels.w = Camera::depth_to_z(depth_texels.w);

    //offsets for xyzw components
    const uint2 offsets[4] = {uint2(0, 1), uint2(1, 1), uint2(1, 0), uint2(0, 0)};

    [unroll]
    for(uint j = 0; j < 4; j++)
    {
        uint2 write_pos = deinterleave_pos(i.dispatchthreadid.xy * 2 + offsets[j], DEINT_TILES, BUFFER_SCREEN_SIZE);
        tex2Dstore(stZSrc, write_pos, depth_texels[j]);
    }
}
#else 
void DepthInterleavePS(in VSOUT i, out float o : SV_Target0)
{ 
    float2 corrected_uv = Depth::correct_uv(i.uv);
    //can't use gather here because DX9 IS A JACKASS
    //ReShade's emulation of that produces 256 temp registers for whatever reason
    float4 depth_texels; 
    depth_texels.x = tex2Dlod(DepthInput, corrected_uv + float2(0.5, 0.5) * BUFFER_PIXEL_SIZE, 0).x;
    depth_texels.y = tex2Dlod(DepthInput, corrected_uv + float2(-0.5, 0.5) * BUFFER_PIXEL_SIZE, 0).x;
    depth_texels.z = tex2Dlod(DepthInput, corrected_uv + float2(0.5, -0.5) * BUFFER_PIXEL_SIZE, 0).x;
    depth_texels.w = tex2Dlod(DepthInput, corrected_uv + float2(-0.5, -0.5) * BUFFER_PIXEL_SIZE, 0).x;
    depth_texels = Depth::linearize(depth_texels);
    depth_texels.x = Camera::depth_to_z(depth_texels.x);
    depth_texels.y = Camera::depth_to_z(depth_texels.y);
    depth_texels.z = Camera::depth_to_z(depth_texels.z);
    depth_texels.w = Camera::depth_to_z(depth_texels.w);

    float maxv = maxc(depth_texels);
    float minv = minc(depth_texels);
    float median = (dot(depth_texels, 1) - minv - maxv) * 0.5; //avg of 2 middle values

    o = median;
}
#endif

float3 ray_hemi_cosine(float2 u, float3 n)
{
    float3 dir;
    sincos(u.x * 3.1415927 * 2,  dir.y,  dir.x);        
    dir.z = u.y * 2.0 - 1.0; 
    dir.xy *= sqrt(1.0 - dir.z * dir.z);
    return normalize(dir + n); 
}

struct RayDesc 
{
    float3 origin;
    float3 pos;
    float3 dir;
    float2 uv;
    float length;    
};

float spline(float l)
{
    return exp2(10.0 * (l - 1));
    //return l*l;
   // return l * (l * (1.25 * l - 0.375) + 0.125);
}

float trace_ray_refine(inout RayDesc ray, inout TraceContext _this, in float3 rand, in float maxT)
{    
    float cosv = dot(ray.dir, _this.viewdir);
    float hit_tolerance = RT_Z_THICKNESS * RT_Z_THICKNESS * (1 + abs(cosv));

    float incT = 1.0 / RT_RAY_STEPS * rsqrt(saturate(1.0 - cosv * cosv));

    ray.origin = _this.pos;
    float currT = incT * rand.z;
    float lastT = 0;
    float hit = 0;

    float3 pos = -1;   

    //linear search
    while(1)
    {        
        ray.length = spline(currT) * maxT;
        if(ray.length > maxT) break;
        ray.pos = ray.origin + ray.dir * ray.length;
        ray.uv = Camera::proj_to_uv(ray.pos);
        if(!Math::inside_screen(ray.uv)) break;

        float z = tex2Dlod(ZTexture, _this.uv.xy + (ray.uv - _this.uv.zw) / DEINT_TILES, 0).x;     
             
        float delta = z - ray.pos.z;

        float t = hit_tolerance * (ray.length + maxT * 0.01); //closes gaps

        [branch]
        if(abs(delta * 2.0 + t) < t)
        { 
            pos = Camera::uv_to_proj(ray.uv, z); 
            hit = saturate(1 - currT); 
            break;   
        }

        lastT = currT;
        currT += incT;        
    }

    //bisection refine
    if(hit > 0)
    {
        const uint num_refine_steps = 4;
        [loop]
        for(uint s = 0; s < num_refine_steps; s++)
        {
            float midT = lerp(lastT, currT, 0.5);
            ray.length = spline(midT) * maxT;

            ray.pos = ray.origin + ray.dir * ray.length;
            ray.uv = Camera::proj_to_uv(ray.pos);

            float z = tex2Dlod(ZTexture, _this.uv.xy + (ray.uv - _this.uv.zw) / DEINT_TILES, 0).x;          
            float delta = z - ray.pos.z;

            float t = hit_tolerance * (ray.length + maxT * 0.01); //closes gaps

            if(abs(delta * 2.0 + t) < t) //hit in the middle, refine first half
            {
                currT = midT; 
                hit = saturate(1 - spline(currT));
            }                  
            else
            {
                lastT = midT;
            } 
        }
    }  

    if(RT_HIGHP_LIGHT_SPREAD && hit > 0.01)
        ray.dir = normalize(lerp(pos - ray.origin, ray.dir, saturate(0.111 * ray.length)));         

    return hit;
}

float4 trace_gi(inout TraceContext _this)
{
    if(get_fade_factor(Camera::z_to_depth(_this.pos.z)) < 0.01) 
        return 0;

    float3 jitter = get_jitter_stbn_4(_this.texel.zw, FRAMECOUNT);
    uint seed = (FRAMECOUNT % 4u) * RT_RAY_AMOUNT;
    
    float3 strat = QMC::get_stratificator(RT_RAY_AMOUNT);
    float4 rtgi = 0;

    float maxT = RT_SAMPLE_RADIUS * RT_SAMPLE_RADIUS;
    uint r = 0;

    [loop]
    for(int r = 0; r < RT_RAY_AMOUNT; r++)
    { 
        float3 rand = QMC::roberts3(r + seed, jitter);
        rand.xy = QMC::get_stratified_sample(rand.yx, strat, r); //swap order to have Z better distributed than XY 

        RayDesc ray;
        ray.dir = ray_hemi_cosine(rand.xy, _this.normal);
        float hit = trace_ray_refine(ray, _this, rand, maxT);

        [branch]
        if(hit > 0.01)
        {    
            float3 hit_n = Deferred::get_normals(ray.uv);
            float facing = saturate(dot(-hit_n, ray.dir) * 32.0);
            float4 albedofetch = tex2Dlod(sRadianceTex, ray.uv, 0);
            float3 albedo = albedofetch.rgb * albedofetch.a * facing; //mask out sky
            rtgi += float4(albedo * hit, hit);       
        }         
    }    

    rtgi /= RT_RAY_AMOUNT;
#if ENABLE_IMAGE_BASED_LIGHTING
    rtgi.rgb += eval_probe(_this, jitter) * saturate(RT_IBL_AMOUNT * RT_IBL_AMOUNT);
#endif
    return rtgi;
}


//Needs this because DX9 is a jackass and doesn't have bitwise ops... so emulate them with floats
bool bitfield_get(float bitfield, int bit)
{
    float state = floor(bitfield * exp2(-bit)); //"right shift"
    return frac(state * 0.5) > 0.25; //"& 1"
}

void bitfield_set(inout float bitfield, int bit, bool value)
{
    bool is_set = bitfield_get(bitfield, bit);
    bitfield += exp2(bit) * (value - is_set);    
}

//tried many things like LUTs, or'ing bits 4 at a time and what not, the stupid and straightforward approach is best
float bitfield_set_bits(float bitfield, int start, int stride, out float num_changed)
{ 
    num_changed = 0;
    [loop]
    for(int bit = start; bit < start + stride; bit++)
    {
        bool is_set = bitfield_get(bitfield, bit);
        num_changed += 1.0 - is_set;
        bitfield += exp2(bit) * (1.0 - is_set); 
    }
       
    return bitfield;
}

float bitfield_countones(float bitfield)
{  
    float sum = 0;
    [loop]
    for(int bit = 0; bit < 24; bit++)
        sum += bitfield_get(bitfield, bit);
    return sum;
}

float4 trace_gi_bitfields(inout TraceContext _this)
{
    if(get_fade_factor(Camera::z_to_depth(_this.pos.z)) < 0.01) 
        return 0;

    float3 jitter = get_jitter_stbn_4(_this.texel.zw, FRAMECOUNT);
    uint seed = (FRAMECOUNT % 4u) * RT_RAY_AMOUNT;
     float3 strat = QMC::get_stratificator(RT_RAY_AMOUNT);

    float4 rtgi = 0;

    uint slice_count  = RT_RAY_AMOUNT;    
    uint sample_count = RT_RAY_STEPS;

    float3 slice_dir = 0; sincos(jitter.x * PI / slice_count, slice_dir.x, slice_dir.y);  
    float4 slice_rotator = Math::get_rotator(PI / slice_count);

    float worldspace_radius = RT_SAMPLE_RADIUS * RT_SAMPLE_RADIUS * 0.5;
    float screenspace_radius = worldspace_radius / _this.pos.z * 0.5;

    float visibility = 0;
    float slicesum = 0;  
    float T = 0.25 * worldspace_radius * RT_Z_THICKNESS * RT_Z_THICKNESS;  //arbitrary thickness that looks good relative to sample radius  
    float falloff_factor = rcp(worldspace_radius);
    falloff_factor *= falloff_factor;

    static const float4 texture_scale = float4(1.0.xx / DEINT_TILES, 1.0.xx) * BUFFER_ASPECT_RATIO.xyxy;

    float3 v = -_this.viewdir;
    float3 n = _this.normal;

    while(slice_count-- > 0) //1 less register and a bit faster
    {        
        slice_dir.xy = Math::rotate_2D(slice_dir.xy, slice_rotator);
        float3 ortho_dir = slice_dir - dot(slice_dir.xy, v.xy) * v; //z = 0 so no need for full dot3
        
        float3 slice_n = cross(slice_dir, v); 
        slice_n *= rsqrt(dot(slice_n, slice_n));   

        float4 scaled_dir = (slice_dir.xy * screenspace_radius).xyxy * texture_scale; 

        float3 n_proj_on_slice = n - slice_n * dot(n, slice_n);
        float sliceweight = sqrt(dot(n_proj_on_slice, n_proj_on_slice));
          
        float cosn = saturate(dot(n_proj_on_slice, v) * rcp(sliceweight));
        float normal_angle = Math::fast_acos(cosn) * Math::fast_sign(dot(ortho_dir, n_proj_on_slice));

#if _COMPUTE_SUPPORTED
        uint occlusion_bitfield = 0xFFFFFFFF;
#else
        float occlusion_bitfield = 0; 
#endif

        [unroll]
        for(int side = 0; side < 2; side++)
        {            
            [loop]         
            for(int _sample = 0; _sample < sample_count; _sample++)
            {              
                float rand = QMC::roberts1(slice_count * 2 + side, jitter.z);
                float s = (_sample + rand) / sample_count;               
                s = spline(s);

                float4 tap_uv = _this.uv + s * scaled_dir;
                if(!all(saturate(tap_uv.zw - tap_uv.zw * tap_uv.zw))) break;
                float zz = tex2Dlod(ZTexture, tap_uv.xy, 0).x; 

                float3 deltavec = Camera::uv_to_proj(tap_uv.zw, zz) - _this.pos;

                float ddotv = dot(deltavec, v);
                float ddotd = dot(deltavec, deltavec);
                float2 h_frontback = float2(ddotv, ddotv - T) * rsqrt(float2(ddotd, ddotd - 2 * T * ddotv + T * T));

                h_frontback = Math::fast_acos(h_frontback);
                h_frontback = side ? h_frontback : -h_frontback.yx;//flip sign and sort in the same cmov, efficiency baby!
                h_frontback = saturate((h_frontback + normal_angle) / PI + 0.5);

                h_frontback = h_frontback * h_frontback * (3.0 - 2.0 * h_frontback);               
#if _COMPUTE_SUPPORTED
                uint a = uint(h_frontback.x * 32);
                uint b = round(saturate(h_frontback.y - h_frontback.x) * 32); //ceil? using half occlusion here
                uint occlusion = ((1 << b) - 1) << a;                
                
                uint local_bitfield = occlusion_bitfield & ~occlusion;
                uint changed_bits = local_bitfield ^ occlusion_bitfield;
#else 
                uint a = floor(h_frontback.x * 24);
                float changed_bits;
                uint b = floor(saturate(h_frontback.y - h_frontback.x) * 25.0); //haven't figured out why this needs to be one more (gives artifacts otherwise) but whatever, somethingsomething float inaccuracy
                float local_bitfield = bitfield_set_bits(occlusion_bitfield, a, b, changed_bits);
#endif
                if(changed_bits > 0)
                {
#if _COMPUTE_SUPPORTED
                    float hit = saturate(countbits(changed_bits) / 32.0) * sliceweight;
#else 
                    float hit = saturate(changed_bits / 24.0) * sliceweight;
#endif
                    rtgi.w += hit;
  
                    if(dot(deltavec, _this.normal) > 0)
                    {
                        float3 hit_n = Deferred::get_normals(tap_uv.zw);
                        float facing = saturate(dot(-hit_n, deltavec) * 32.0);
                        float4 albedofetch = tex2Dlod(sRadianceTex, tap_uv.zw, 0);
                        float3 albedo = albedofetch.rgb * albedofetch.a * facing; //mask out sky
                        rtgi.rgb += albedo * hit;
                    }                    
                }               
                occlusion_bitfield = local_bitfield;
            }        
            scaled_dir = -scaled_dir;
        }

        slicesum += sliceweight;
    }

    rtgi /= slicesum;
#if ENABLE_IMAGE_BASED_LIGHTING
    rtgi.rgb += eval_probe(_this, jitter) * saturate(RT_IBL_AMOUNT * RT_IBL_AMOUNT);
#endif
    return rtgi;
}

float3 convert_gi_to_lighting(float4 raw_gi)
{
#if ENABLE_IMAGE_BASED_LIGHTING   
    float base_exposure = saturate(1.0 - RT_IBL_AMOUNT * RT_IBL_AMOUNT * 0.65);
    float3 lighting = (1.0 - raw_gi.w * saturate(RT_AO_AMOUNT * 0.1)) * base_exposure + raw_gi.rgb * RT_IL_AMOUNT * RT_IL_AMOUNT * 2;
#else
    float3 lighting = 1.0 - raw_gi.w * saturate(RT_AO_AMOUNT * 0.1) + raw_gi.rgb * RT_IL_AMOUNT * RT_IL_AMOUNT * 2;
#endif
    if(OLD_BLENDING_MATH) lighting = rcp(1 + raw_gi.w * RT_AO_AMOUNT * 2) * (1 + raw_gi.rgb * RT_IL_AMOUNT * RT_IL_AMOUNT * 3);
    return lighting;
}

#if _COMPUTE_SUPPORTED
void TraceWrapCS(in CSIN i)
{ 
    const uint2 tile_size = CEIL_DIV(BUFFER_SCREEN_SIZE, DEINT_TILES);
    if(!check_boundaries(i.dispatchthreadid.xy, tile_size * DEINT_TILES)) 
        return;

    TraceContext _this = init(i.dispatchthreadid.xy, BUFFER_SCREEN_SIZE);    
    float4 gi = trace_gi_bitfields(_this); 
    //float3 lighting = convert_gi_to_lighting(gi);
    //tex2Dstore(stGITex, _this.texel.zw, encode_hdr_to_filter(lighting));
    tex2Dstore(stGITex, _this.texel.zw, gi);
}
#else
void TraceWrapPS(in VSOUT i, out float4 o : SV_Target)
{
    TraceContext _this = init(floor(i.vpos.xy), BUFFER_SCREEN_SIZE);
    float4 gi = trace_gi(_this);
    //float3 lighting = convert_gi_to_lighting(gi);
    //o = encode_hdr_to_filter(lighting);
    o = gi;
}
#endif

void TemporalCombinePS(in VSOUT i, out PSOUT2 o)
{
    float2 motionv = Deferred::get_motion(i.uv);
    float2 repro_uv = i.uv + motionv;

    bool repro_inside_screen = all(saturate(repro_uv - repro_uv * repro_uv));

    float4 gbuf_curr = get_gbuffer(i.uv);          gbuf_curr.xyz = normalize(gbuf_curr.xyz);
    float4 gbuf_prev = get_gbuffer_prev(repro_uv); gbuf_prev.xyz = normalize(gbuf_prev.xyz);

    float dn = dot(gbuf_curr.xyz, gbuf_prev.xyz);
    float dz = abs(gbuf_curr.w - gbuf_prev.w) / (gbuf_curr.w + gbuf_prev.w + 1e-6);
    repro_inside_screen = dn < 0.96 && dz > 0.005 ? false : repro_inside_screen;

    int stacksize = round(tex2Dlod(sHistoryLengthAndVarianceTexPrev, i.uv, 3).z); 
    stacksize = repro_inside_screen ? min(12, ++stacksize) : 1;
    
    float lerpspeed = rcp(stacksize);
    float mip = 0; //max(0, 3 - stacksize); //See test 16 

    float4 gi_prev = tex2D(sGITexPrev, repro_uv);
    float4 gi_curr = tex2Dlod(sGITex, i.uv, mip);
    gi_curr = encode_hdr_to_filter(convert_gi_to_lighting(gi_curr));

    //variance clipping of history
    float3 spatial_m1 = 0, spatial_m2 = 0;

    [unroll]for(int x = -2; x <= 2; x++)
    [unroll]for(int y = -2; y <= 2; y++)
    {
        float4 t = tex2Dlod(sGITex, i.uv + float2(x, y) * BUFFER_PIXEL_SIZE * exp2(mip), mip); 
        t = encode_hdr_to_filter(convert_gi_to_lighting(t));      
        spatial_m1 += t.rgb; spatial_m2 += t.rgb * t.rgb;
    }

    spatial_m1 /= 25.0; spatial_m2 /= 25.0;
    float3 spatial_variance = sqrt(abs(spatial_m2 - spatial_m1 * spatial_m1));
    float3 aabb_range = spatial_variance * 0.5;

#ifndef DEBUG_DISABLE_FILTER
    gi_prev = Math::aabb_clip(gi_prev.rgb, spatial_m1 - aabb_range, spatial_m1 + aabb_range); 
#endif

    float3 gi = lerp(gi_prev.rgb, gi_curr.rgb, lerpspeed);

    float2 temporal_m12_prev = tex2D(sHistoryLengthAndVarianceTexPrev, repro_uv).xy;
    float2 temporal_m12_curr = gi_curr.zw;
    float2 spatial_m12_curr = float2(spatial_m1.z, spatial_m2.z);

    float2 temporal_m12_integrated = lerp(temporal_m12_prev, temporal_m12_curr, lerpspeed);
    temporal_m12_integrated = lerp(temporal_m12_integrated, spatial_m12_curr, saturate(mip / 3.0)); //use this if history is unreliable

    bool is_sky_or_faded = get_fade_factor(Camera::z_to_depth(gbuf_curr.w)) < 0.01;
   
    o.t0 = float4(gi, gbuf_curr.w); //pack z for filter
    o.t1 = float4(temporal_m12_integrated, stacksize, is_sky_or_faded);
}

void StorePrevPS(in VSOUT i, out PSOUT3 o)
{
#ifdef DEBUG_DISABLE_FILTER
    o.t0 = tex2D(sGIFilterTemp, i.uv);
#else 
    o.t0 = tex2D(sGIFilterTemp2, i.uv);
#endif
    o.t1 = get_gbuffer(i.uv);

    float4 offs = mad(BUFFER_PIXEL_SIZE.xyxy, float4(-2, -2, 2, 2), i.uv.xyxy);
    o.t2  = tex2Dlod(sHistoryLengthAndVarianceTex, offs.xy, 2);
    o.t2 += tex2Dlod(sHistoryLengthAndVarianceTex, offs.xw, 2);
    o.t2 += tex2Dlod(sHistoryLengthAndVarianceTex, offs.zy, 2);
    o.t2 += tex2Dlod(sHistoryLengthAndVarianceTex, offs.zw, 2);
    o.t2 /= 4.0;    
}

struct FilterSample
{
    float4 gbuffer;
    float3 val;
};

FilterSample get_filter_sample(in float2 uv, sampler gi)
{    
    FilterSample o;
    o.gbuffer.rgb = Deferred::get_normals(uv);
    float4 t = tex2Dlod(gi, uv, 0);
    o.gbuffer.w = t.w;
    o.val = t.rgb;
    return o;
}

float2x3 to_tangent(float3 n)
{
    bool bestside = n.z < n.y;
    float3 n2 = bestside ? n.xzy : n;
    float3 k = (-n2.xxy * n2.xyy) * rcp(1.0 + n2.z) + float3(1, 0, 1);
    float3 u = float3(k.xy, -n2.x);
    float3 v = float3(k.yz, -n2.y);
    u = bestside ? u.xzy : u;
    v = bestside ? v.xzy : v;
    return float2x3(u, v);
}

float4 atrous(float2 center_uv, sampler gi, uint iteration)
{
    if(tex2D(sHistoryLengthAndVarianceTex, center_uv).w > 0.5) return 1;

    float4 offs = mad(BUFFER_PIXEL_SIZE.xyxy, float4(-2.0, -2.0, 2.0, 2.0), center_uv.xyxy);
    float2 tmoments  = tex2Dlod(sHistoryLengthAndVarianceTex, offs.xy, 2).xy;
           tmoments += tex2Dlod(sHistoryLengthAndVarianceTex, offs.xw, 2).xy;
           tmoments += tex2Dlod(sHistoryLengthAndVarianceTex, offs.zy, 2).xy;
           tmoments += tex2Dlod(sHistoryLengthAndVarianceTex, offs.zw, 2).xy;
           tmoments /= 4.0;
    float variance = abs(tmoments.y - tmoments.x * tmoments.x);        

    FilterSample center = get_filter_sample(center_uv, gi);

#ifdef DEBUG_DISABLE_FILTER
    if(center_uv.x < 5.0) return tex2Dlod(gi, center_uv, 0);
#endif

    float3 center_pos = Camera::uv_to_proj(center_uv, center.gbuffer.w);    

    float sz = 250.0;
    float sn = 8.0;
    float sv = rsqrt(1e-3 + variance);

    float smoothness = 3.9;

    sv = rsqrt(1e-3 + variance * 0.08 * smoothness);

    float4 sum = float4(center.val, 1);
    float3 minv = 1000;
    float3 maxv = -1000;

    float3 n = center.gbuffer.xyz;
    float3 p = Camera::uv_to_proj(center_uv, center.gbuffer.w);

    float2x3 kernel_matrix = to_tangent(n);

    int j = 0;

    static const float3 g_Special8[ 8 ] =
{
    // https://www.desmos.com/calculator/abaqyvswem
    float3( -1.00             ,  0.00             , 1.0 ),
    float3(  0.00             ,  1.00             , 1.0 ),
    float3(  1.00             ,  0.00             , 1.0 ),
    float3(  0.00             , -1.00             , 1.0 ),
    float3( -0.25 * sqrt(2.0) ,  0.25 * sqrt(2.0) , 0.5 ),
    float3(  0.25 * sqrt(2.0) ,  0.25 * sqrt(2.0) , 0.5 ),
    float3(  0.25 * sqrt(2.0) , -0.25 * sqrt(2.0) , 0.5 ),
    float3( -0.25 * sqrt(2.0) , -0.25 * sqrt(2.0) , 0.5 )
};

    float randang = get_jitter_stbn_4(center_uv * BUFFER_SCREEN_SIZE, 0).x;
    float4 rotator = Math::get_rotator(TAU * randang + iteration * TAU + (FRAMECOUNT % 16));


    [unroll]for(int y = -1; y <= 1; y++)
    [unroll]for(int x = -1; x <= 1; x++)
    {
        if(x == 0 && y == 0) continue;
        float2 tap_uv = center_uv + float2(x, y) * exp2(iteration) * BUFFER_PIXEL_SIZE;   
        FilterSample tap = get_filter_sample(tap_uv, gi);

        float3 tap_pos = Camera::uv_to_proj(tap_uv, tap.gbuffer.w);
        float proj_on_n = dot(tap_pos - center_pos, center.gbuffer.xyz) / center_pos.z * sz;
        float wz = exp2(-proj_on_n * proj_on_n);

        float wn = saturate(dot(tap.gbuffer.xyz, center.gbuffer.xyz) * (sn + 1) - sn);
        //wn = lerp(wn, 1, wz * wz);
        
        float wv = dot(abs(tap.val - center.val), float3(0.1, 0.1, 0.8));//cocgy                
        wv = exp2(-wv * wv * sv * sv);
        wv *= wv;  wv *= wv;       
        
        float w = wz * wn * wv;
        sum += float4(tap.val, 1) * w;

        minv = min(minv, tap.val);
        maxv = max(maxv, tap.val);
    }

    sum.rgb /= sum.w;
    sum.rgb = clamp(sum.rgb, minv, maxv);  

    sum.w = center.gbuffer.w;
    return sum;
}

void FilterPS0(in VSOUT i, out float4 o : SV_Target0){ o = atrous(i.uv, sGIFilterTemp,  0); }
void FilterPS1(in VSOUT i, out float4 o : SV_Target0){ o = atrous(i.uv, sGIFilterTemp2, 1); }
void FilterPS2(in VSOUT i, out float4 o : SV_Target0){ o = atrous(i.uv, sGIFilterTemp,  2); }
void FilterPS3(in VSOUT i, out float4 o : SV_Target0){ o = atrous(i.uv, sGIFilterTemp2, 3); }

void BlendPS(in VSOUT i, out float3 o : SV_Target0)
{ 
    o = tex2D(ColorInput, i.uv).rgb;
    if(RT_DEBUG_VIEW == 2 && i.uv.x < 0.35 + (i.uv.y - 0.5) * -0.15) return;
    if((RT_DEBUG_VIEW && i.uv.x < (1-0.35) + (i.uv.y - 0.5) * -0.15) || RT_DEBUG_VIEW == 1) o = 0.444;
    o = unpack_hdr(o);

    float3 gi = tex2D(sGIFilterTemp, i.uv).rgb;    
    gi = decode_hdr_from_filter(gi);
    
    float fade = get_fade_factor(Depth::get_linear_depth(i.uv));
    gi = lerp(1, gi, fade);

    o *= gi;
    o = pack_hdr(o);
}

void SHProbeGeneratePS(in VSOUT i, out float4 o : SV_Target0)
{
    uint2 p = i.vpos.xy;
    uint channel = p.y / PROBE_VOLUME_RES;
    
    int3 probe_id = int3(p.xy % PROBE_VOLUME_RES, floor(p.x / PROBE_VOLUME_RES));
    float3 probe_ndc = probe_id / float(PROBE_VOLUME_RES - 1.0); 
    probe_ndc = probe_to_screen(probe_ndc);

    float3 probe_pos = Camera::uv_to_proj(probe_ndc.xy, Camera::depth_to_z(probe_ndc.z));
    float scene_z = tex2Dlod(sGBufferTexPrev, probe_ndc.xy, 0).w;

    float4 po = tex2D(sSHProbeTexPrev, i.uv);
    o = 0;

    [branch]
    if(abs(scene_z-probe_pos.z)/min(scene_z, probe_pos.z) < 1.5) 
    {
    	//probe_pos.z = min(probe_pos.z, scene_z);
        const uint2 grid_size = uint2(16 * BUFFER_ASPECT_RATIO.yx);
        float2 jitter = QMC::roberts2(FRAMECOUNT % 64, tex2Dfetch(sJitterTexSTBN, p.xy % 128u).xy);
        float4 probe_harmonics = 0;

        float4 sh_coeffs = float4(0.282094791, 0.4886025119, -0.4886025119, -0.4886025119);
        
        float SHSharpness = 1.0;    
        const float sh_c0 = (2.0 - SHSharpness) * 1.0;
        const float sh_c1 = SHSharpness * 2.0 / 3.0;
        sh_coeffs *= float4(sh_c0, sh_c1, sh_c1, sh_c1);

        [loop]for(int x = 0; x < grid_size.x; x++)
        [loop]for(int y = 0; y < grid_size.y; y++)
        {
            float2 grid_uv = (float2(x, y) + jitter) / grid_size;

            float4 irradiance = tex2Dlod(sRadianceTex, grid_uv, 0);  
            irradiance *= irradiance.w; //sky   
    
            float4 gbuf = tex2Dlod(sGBufferTexPrev, grid_uv, 0);        
            float3 sp = Camera::uv_to_proj(grid_uv, gbuf.w);

            float3 deltav = sp - probe_pos;
            float dist2 = dot(deltav, deltav);
            deltav *= rsqrt(dist2);
            float facing = saturate(-dot(deltav, gbuf.xyz));
            deltav = normalize(deltav);
            probe_harmonics += sh_coeffs * float4(1, deltav.zyx) * (irradiance[channel] * facing * rcp(1 + dist2));
        }

        probe_harmonics /= grid_size.x * grid_size.y;
        o = probe_harmonics * 16384.0;
    }

    o = lerp(po, o, 0.01);
}

void SHProbeStorePS(in VSOUT i, out float4 o : SV_Target0)
{
    o = tex2D(sSHProbeTex, i.uv);
}
/*=============================================================================
	Techniques
=============================================================================*/

technique MartysMods_RTGI
<
    ui_label = "iMMERSE Pro RTGI";
    ui_tooltip =        
        "                                MartysMods - RTGI                                 \n"
        "                     MartysMods Epic ReShade Effects (iMMERSE)                    \n"
        "               Official versions only via https://patreon.com/mcflypg             \n"
        "__________________________________________________________________________________\n"
        "\n"
        "RTGI adds fully dynamic, realistic and immersive ray traced lighting to your games\n"
        "to enhance existing lighting or to completely relight your scene, depending on the\n"
        "use case.\n"
        "Make sure iMMERSE LAUNCHPAD is enabled and placed at the top of the effect list!    "
        "\n"
        "\n"
        "Visit https://martysmods.com for more information.                                \n"
        "\n"       
        "__________________________________________________________________________________\n"
        "Version: 0.42";
>
{  

#if _COMPUTE_SUPPORTED
pass { ComputeShader = DepthInterleaveCS<32, 32>;DispatchSizeX = CEIL_DIV(BUFFER_WIDTH, 64);DispatchSizeY = CEIL_DIV(BUFFER_HEIGHT, 64); }
#else 
pass { VertexShader = MainVS; PixelShader = DepthInterleavePS; RenderTarget = ZSrcLo; }
#endif
pass { VertexShader = MainVS; PixelShader = AlbedoInputPS; RenderTarget0 = RadianceTex; }   
#if ENABLE_IMAGE_BASED_LIGHTING
pass { VertexShader = MainVS; PixelShader = SHProbeGeneratePS; RenderTarget0 = SHProbeTex; } 
pass { VertexShader = MainVS; PixelShader = SHProbeStorePS; RenderTarget0 = SHProbeTexPrev; } 
#endif
#if _COMPUTE_SUPPORTED
pass { ComputeShader = TraceWrapCS<16, 16>; DispatchSizeX = CEIL_DIV(BUFFER_WIDTH, 16); DispatchSizeY = CEIL_DIV(BUFFER_HEIGHT, 16); }
#else 
pass { VertexShader = MainVS; PixelShader = TraceWrapPS; RenderTarget0 = GITex; } 
#endif
pass { VertexShader = MainVS; PixelShader = TemporalCombinePS; RenderTarget0 = GIFilterTemp; RenderTarget1 = HistoryLengthAndVarianceTex; } 
pass { VertexShader = MainVS; PixelShader = FilterPS0; RenderTarget0 = GIFilterTemp2; } 
pass { VertexShader = MainVS; PixelShader = FilterPS1; RenderTarget0 = GIFilterTemp; }
pass { VertexShader = MainVS; PixelShader = StorePrevPS; RenderTarget = GITexPrev; RenderTarget1 = GBufferTexPrev; RenderTarget2 = HistoryLengthAndVarianceTexPrev; } 
pass { VertexShader = MainVS; PixelShader = FilterPS2; RenderTarget0 = GIFilterTemp2; } 
pass { VertexShader = MainVS; PixelShader = FilterPS3; RenderTarget0 = GIFilterTemp; } 
pass { VertexShader = MainVS; PixelShader = BlendPS; }
}
