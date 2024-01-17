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

    Solaris Bloom

    Author:         Pascal Gilcher

    More info:      https://martysmods.com
                    https://patreon.com/mcflypg
                    https://github.com/martymcmodding  	

=============================================================================*/

/*=============================================================================
	Preprocessor settings
=============================================================================*/

#ifndef ENABLE_SOLARIS_REGRADE_PARITY
 #define ENABLE_SOLARIS_REGRADE_PARITY                  0   //[0 or 1]    If enabled, ReGrade takes HDR input from SOLARIS as color buffer instead. This allows HDR exposure, bloom and color grading to work nondestructively
#endif

#ifndef SOLARIS_PERF_MODE
 #define SOLARIS_PERF_MODE                              0
#endif 

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform float HDR_EXPOSURE <
	ui_type = "drag";
	ui_min = -5.0; ui_max = 5.0;
	ui_label = "Log Exposure Bias";
> = 0.0;

uniform float HDR_WHITEPOINT <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 12.0;
    ui_label = "Log HDR Whitepoint";
> = 7.0;

uniform float HDR_BLOOM_INT <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Bloom Intensity";
> = 0.3;

uniform float HDR_BLOOM_RADIUS <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Bloom Radius";
> = 1.0;

uniform float HDR_BLOOM_HAZYNESS <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Bloom Hazyness";
> = 0.9;

uniform bool BLOOM_HQ_DOWNSAMPLING <
    ui_label = "High Resolution Input";
> = false;

uniform bool BLOOM_DEPTH_MASK <
    ui_label = "Mask by Depth";
> = true;

uniform float BLOOM_DEPTH_MASK_STRENGTH <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Depth Mask Strength";
> = 0.5;

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
*/

/*=============================================================================
	Textures, Samplers, Globals, Structs
=============================================================================*/

#if SOLARIS_PERF_MODE > 2
 #undef SOLARIS_PERF_MODE
 #define SOLARIS_SHARPNESS 2
#endif
#if SOLARIS_PERF_MODE < 0
 #undef SOLARIS_PERF_MODE
 #define SOLARIS_PERF_MODE 0
#endif

//max screen width allowed, everything above will get downscaled
#define LOG_MAX_RES     (11  - SOLARIS_PERF_MODE)   //0: 2048, 1: 1024, 2: 512

#define BASE_SIZE_X     (1 << LOG_MAX_RES)
#define BASE_SIZE_Y     (BASE_SIZE_X * BUFFER_HEIGHT) / BUFFER_WIDTH

#define MAKE_TEXTURE(N) texture Bloom##N { Width = BASE_SIZE_X >> N; Height = BASE_SIZE_Y >> N; Format = RGBA16F;  }; sampler sBloom##N { Texture = Bloom##N;  };  


MAKE_TEXTURE(0)
MAKE_TEXTURE(1)
MAKE_TEXTURE(2)
MAKE_TEXTURE(3)
MAKE_TEXTURE(4)
#if SOLARIS_PERF_MODE <= 1
MAKE_TEXTURE(5)
#endif
#if SOLARIS_PERF_MODE <= 0
MAKE_TEXTURE(6)
#endif

texture BloomOut { Width = BASE_SIZE_X; Height = BASE_SIZE_Y; Format = RGBA16F;  }; 
sampler sBloomOut { Texture = BloomOut; };

texture ColorInputTex : COLOR;
texture DepthInputTex : DEPTH;
sampler ColorInput 	{ Texture = ColorInputTex;};
sampler ColorInputPoint 	{ Texture = ColorInputTex; MinFilter = POINT; MipFilter = POINT; MagFilter = POINT; };
sampler DepthInput 	{ Texture = DepthInputTex;};

#if ENABLE_SOLARIS_REGRADE_PARITY != 0
texture2D ColorInputHDRTex			    { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA16F; };
sampler2D sColorInputHDR			    { Texture = ColorInputHDRTex;  };
#endif

#include ".\MartysMods\mmx_global.fxh"
#include ".\MartysMods\mmx_depth.fxh"
#include ".\MartysMods\mmx_sampling.fxh"
#include ".\MartysMods\mmx_colorspaces.fxh"

struct VSOUT
{
	float4 vpos : SV_Position;
    float2 uv   : TEXCOORD0;    
};

/*=============================================================================
	Functions
=============================================================================*/

float3 cone_overlap(float3 c)
{
    float k = 0.4 * 0.33;
    float2 f = float2(1 - 2 * k, k);
    float3x3 m = float3x3(f.xyy, f.yxy, f.yyx);
    return mul(c, m);
}

float3 cone_overlap_inv(float3 c)
{
    float k = 0.4 * 0.33;
    float2 f = float2(k - 1, k) * rcp(3 * k - 1);
    float3x3 m = float3x3(f.xyy, f.yxy, f.yyx);
    return mul(c, m);
}

float3 sdr_to_hdr(float3 c, float w)
{ 
    c = cone_overlap(c);
    c = c * sqrt(1e-6 + dot(c, c)) / 1.733; 
    float a = 1 + exp2(-w);    
    c = c / (a - c); 
    return c;
}

float3 hdr_to_sdr(float3 c, float w)
{    
    float a = 1 + exp2(-w); 
    c = a * c * rcp(1 + c);
    c *= 1.733;
    c = c * rsqrt(sqrt(dot(c, c))+0.0001);
    c = cone_overlap_inv(c);
    return c;
}

float4 downsample(sampler tex, float2 uv)
{
    float4 offs = float4(2.0, 2.0, 4.0, 4.0) * rcp(tex2Dsize(tex)).xyxy;
    float3 offsets[12] = 
    {
        float3(-offs.x, -offs.y, 4.0),        
        float3( offs.x, -offs.y, 4.0),
        float3(-offs.x,  offs.y, 4.0),
        float3( offs.x,  offs.y, 4.0),
        float3(0, -offs.w, 2.0),
        float3(-offs.z, 0, 2.0),
        float3( offs.z, 0, 2.0),
        float3(0,  offs.w, 2.0),             
        float3( offs.z,  offs.w, 1.0),
        float3(-offs.z,  offs.w, 1.0),
        float3( offs.z, -offs.w, 1.0),
        float3(-offs.z, -offs.w, 1.0)
    };

    float4 sum = tex2D(tex, uv);
    float centerdepth = sum.w;
    sum *= 4.0;
    float wsum = 4.0;

    [unroll]
    for(int j = 0; j < 12; j++)
    {
        float4 tap = tex2D(tex, uv + offsets[j].xy);
        float w = BLOOM_DEPTH_MASK ? saturate(exp2(-(tap.w - centerdepth) / centerdepth * BLOOM_DEPTH_MASK_STRENGTH * 0.5)) : 1;
        w *= offsets[j].z;
        sum += tap * w;
        wsum += w;
    }

    return sum / wsum;  
}

float4 upsample(sampler2D tex, float2 uv)
{   
	float4 sum = tex2D(tex, uv);
    float centerdepth = sum.w;
    sum *= 2.0;
    float wsum = 2.0;

    float2 offs = 1.5 * rcp(tex2Dsize(tex)); 

    //batch texture fetches for more registers and fewer cycles
    float4 tap[4] = 
    {
        tex2D(tex, float2(uv.x + offs.x, uv.y)),
        tex2D(tex, float2(uv.x - offs.x, uv.y)),
        tex2D(tex, float2(uv.x, uv.y + offs.y)),
        tex2D(tex, float2(uv.x, uv.y - offs.y))
    };

    [branch]
    if(BLOOM_DEPTH_MASK)
    {
        float4 w = float4(tap[0].w, tap[1].w, tap[2].w, tap[3].w);
        w = saturate(exp2(-(w - centerdepth) / centerdepth * BLOOM_DEPTH_MASK_STRENGTH * 0.5));        
        sum += tap[0] * w.x;
        sum += tap[1] * w.y;
        sum += tap[2] * w.z;
        sum += tap[3] * w.w;
        wsum += dot(w, 1);
    }
    else 
    {
        sum += (tap[0] + tap[1]) + (tap[2] + tap[3]);
        wsum += 4;
    }

    return sum / wsum;  
}

//depth masking works on relative values so even though
//this scales alpha as well, it does not interfere
float layerweight(float i)
{
    return exp2(-i * 0.5 * (1 - sqrt(HDR_BLOOM_RADIUS)));
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

void PrepassPS(in VSOUT i, out float4 o : SV_Target0) 
{
    float2 src_size  = BUFFER_SCREEN_SIZE;
    float2 dest_size = float2(BASE_SIZE_X, BASE_SIZE_Y);

    float2 pixelratio = src_size / dest_size; //e.g 3 pixels, 3840x2160 -> 1.875, 1.054
    o = 0;

    [branch]
    if(BLOOM_HQ_DOWNSAMPLING)
    {
        int2 npixels = ceil(pixelratio);
        float3 sum_sdr = 0;float3 sum_hdr = 0;
        
        [unroll]for(int y = -npixels.y; y <= npixels.y; y++)
        [unroll]for(int x = -npixels.x; x <= npixels.x; x++)
        {
            float3 t = tex2Dlod(ColorInputPoint, i.uv + BUFFER_PIXEL_SIZE * float2(x, y), 0).rgb;
            sum_sdr += t;
            t = sdr_to_hdr(t, HDR_WHITEPOINT);
            sum_hdr += t;
        }

        [branch] //better do this out of the loop...
        if(BLOOM_DEPTH_MASK)
        {            
            [unroll]for(int y = -npixels.y; y <= npixels.y; y++)
            [unroll]for(int x = -npixels.x; x <= npixels.x; x++)
                o.w += Depth::get_linear_depth(i.uv + BUFFER_PIXEL_SIZE  * float2(x, y));               
        }

        sum_sdr /= (2 * npixels.x + 1) * (2 * npixels.y + 1);
        sum_hdr /= (2 * npixels.x + 1) * (2 * npixels.y + 1);
        o.w /= (2 * npixels.x + 1) * (2 * npixels.y + 1);

        sum_sdr = sdr_to_hdr(saturate(sum_sdr), HDR_WHITEPOINT);
        o.rgb = normalize(sum_hdr + 1e-6) * length(sum_hdr);        
    }
    else 
    {
        int2 npixels = round(pixelratio);

        [unroll]for(int y = 0; y < npixels.y; y++)
        [unroll]for(int x = 0; x < npixels.x; x++)        
            o.rgb += tex2Dlod(ColorInput, i.uv + BUFFER_PIXEL_SIZE * (-(npixels - 1) + float2(x, y) * 2), 0).rgb;

        [branch] 
        if(BLOOM_DEPTH_MASK)
        {
            [unroll]for(int y = 0; y < npixels.y; y++) 
            [unroll]for(int x = 0; x < npixels.x; x++)            
                o.w += Depth::get_linear_depth(i.uv + BUFFER_PIXEL_SIZE * (-(npixels - 1) + float2(x, y) * 2));
        }
        o /= npixels.x * npixels.y;
        o.rgb = sdr_to_hdr(saturate(o.rgb), HDR_WHITEPOINT);    
    } 

    o.rgb *= exp2(HDR_EXPOSURE);  
}

void Downsample01PS(  in VSOUT i, out float4 o : SV_Target0) { o = downsample(sBloom0, i.uv) * layerweight(1); }
void Downsample12PS(  in VSOUT i, out float4 o : SV_Target0) { o = downsample(sBloom1, i.uv) * layerweight(2); }
void Downsample23PS(  in VSOUT i, out float4 o : SV_Target0) { o = downsample(sBloom2, i.uv) * layerweight(3); }
void Downsample34PS(  in VSOUT i, out float4 o : SV_Target0) { o = downsample(sBloom3, i.uv) * layerweight(4); }
#if SOLARIS_PERF_MODE <= 1
void Downsample45PS(  in VSOUT i, out float4 o : SV_Target0) { o = downsample(sBloom4, i.uv) * layerweight(5); }
#if SOLARIS_PERF_MODE <= 0
void Downsample56PS(  in VSOUT i, out float4 o : SV_Target0) { o = downsample(sBloom5, i.uv) * layerweight(6); }
void Upsample65PS(  in VSOUT i, out float4 o : SV_Target0) { o =   upsample(sBloom6, i.uv); }
#endif
void Upsample54PS(  in VSOUT i, out float4 o : SV_Target0) { o =   upsample(sBloom5, i.uv); }
#endif
void Upsample43PS(  in VSOUT i, out float4 o : SV_Target0) { o =   upsample(sBloom4, i.uv); }
void Upsample32PS(  in VSOUT i, out float4 o : SV_Target0) { o =   upsample(sBloom3, i.uv); }
void Upsample21PS(  in VSOUT i, out float4 o : SV_Target0) { o =   upsample(sBloom2, i.uv); }
void Upsample10PS(  in VSOUT i, out float4 o : SV_Target0) { o =   upsample(sBloom1, i.uv); }
void UpsampleFinalPS(in VSOUT i, out float4 o : SV_Target0) { o =   upsample(sBloom0, i.uv); }

void BlendPS(in VSOUT i, out float3 o : SV_Target0)
{
    float l1 = layerweight(1);
	float l2 = layerweight(2);
	float l3 = layerweight(3);
	float l4 = layerweight(4);
    float l5 = layerweight(5);
    float l6 = layerweight(6);
#if SOLARIS_PERF_MODE <= 0
    float w = 1 + (l1 * (1 + l2 * (1 + l3 * (1 + l4 * (1 + l5 * (1 + l6))))));
#elif SOLARIS_PERF_MODE <= 1
    float w = 1 + (l1 * (1 + l2 * (1 + l3 * (1 + l4 * (1 + l5)))));
#else 
    float w = 1 + (l1 * (1 + l2 * (1 + l3 * (1 + l4))));
#endif   

    float4 bloom = Sampling::tex2Dbicub(sBloomOut, i.uv); 
    bloom.rgb /= w;

    [branch]
    if(BLOOM_DEPTH_MASK)
    {
        float depth = Depth::get_linear_depth(i.uv);
        float bloomdepth = bloom.w;
        float depthw = saturate(exp2(-(bloomdepth - depth) / depth * BLOOM_DEPTH_MASK_STRENGTH * 0.5));
        depthw = lerp(depthw, 1, 0.15); //only here, lift up a little to avoid weird looking bloom reappearing inside close objects
        bloom.rgb *= depthw;
    }

    bloom.rgb *= exp2(-HDR_WHITEPOINT * 0.25); //visually normalize so observed bloom intensity is agnostic of whitepoint setting    
    float3 col = tex2D(ColorInput, i.uv).rgb;

    col = sdr_to_hdr(col, HDR_WHITEPOINT);    
    col *= exp2(HDR_EXPOSURE);   
    col += lerp(col, 0.05, HDR_BLOOM_HAZYNESS * 0.5 + 0.5) * bloom.rgb * HDR_BLOOM_INT * HDR_BLOOM_INT * 128.0;
    col = hdr_to_sdr(col, HDR_WHITEPOINT);
    o = saturate(col);
}

/*=============================================================================
	Techniques
=============================================================================*/

technique MartysMods_SOLARIS
<
    ui_label = "iMMERSE Pro Solaris";
    ui_tooltip =       
        "                               MartysMods - Solaris                               \n"
        "                     MartysMods Epic ReShade Effects (iMMERSE)                    \n"
        "               Official versions only via https://patreon.com/mcflypg             \n"
        "__________________________________________________________________________________\n"
        "\n"
        "SOLARIS is a novel approach for bloom and exposure control.                       \n"
        "It is designed to work in tandem with REGRADE, an all-purpose color grading effect.\n"
        "Make sure to place this effect right before ReGrade.                              \n"
        "\n"
        "\n"
        "Visit https://martysmods.com for more information.                                \n"
        "\n"       
        "__________________________________________________________________________________\n";
>
{
    pass{VertexShader = MainVS;   PixelShader = PrepassPS; RenderTarget = Bloom0; }
    pass{VertexShader = MainVS;   PixelShader = Downsample01PS;   RenderTarget = Bloom1; }
    pass{VertexShader = MainVS;   PixelShader = Downsample12PS;   RenderTarget = Bloom2; }
    pass{VertexShader = MainVS;   PixelShader = Downsample23PS;   RenderTarget = Bloom3; }
    pass{VertexShader = MainVS;   PixelShader = Downsample34PS;   RenderTarget = Bloom4; }
#if SOLARIS_PERF_MODE <= 1   
    pass{VertexShader = MainVS;   PixelShader = Downsample45PS;   RenderTarget = Bloom5; }
#if SOLARIS_PERF_MODE <= 0
    pass{VertexShader = MainVS;   PixelShader = Downsample56PS;   RenderTarget = Bloom6; }
    pass{VertexShader = MainVS;   PixelShader = Upsample65PS;   RenderTarget = Bloom5; BlendEnable = true;BlendOp = ADD;SrcBlend = ONE;DestBlend = ONE; }
#endif
    pass{VertexShader = MainVS;   PixelShader = Upsample54PS;   RenderTarget = Bloom4; BlendEnable = true;BlendOp = ADD;SrcBlend = ONE;DestBlend = ONE; }
#endif
    pass{VertexShader = MainVS;   PixelShader = Upsample43PS;   RenderTarget = Bloom3; BlendEnable = true;BlendOp = ADD;SrcBlend = ONE;DestBlend = ONE; }
    pass{VertexShader = MainVS;   PixelShader = Upsample32PS;   RenderTarget = Bloom2; BlendEnable = true;BlendOp = ADD;SrcBlend = ONE;DestBlend = ONE; }
    pass{VertexShader = MainVS;   PixelShader = Upsample21PS;   RenderTarget = Bloom1; BlendEnable = true;BlendOp = ADD;SrcBlend = ONE;DestBlend = ONE; }
    pass{VertexShader = MainVS;   PixelShader = Upsample10PS;   RenderTarget = Bloom0; BlendEnable = true;BlendOp = ADD;SrcBlend = ONE;DestBlend = ONE; }    
    pass{VertexShader = MainVS;   PixelShader = UpsampleFinalPS; RenderTarget = BloomOut; } 
#if ENABLE_SOLARIS_REGRADE_PARITY != 0
    pass{VertexShader = MainVS;   PixelShader = BlendPS; RenderTarget = ColorInputHDRTex; } 
#else 
    pass{VertexShader = MainVS;   PixelShader = BlendPS;    }
#endif    
}
