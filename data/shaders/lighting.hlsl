//@surface
#include "shaders/common.hlsli"

// Structure to hold vertex output data
struct VSOutput
{
	float2 uv : TEXCOORD0; // Texture coordinates
	float4 position : SV_POSITION; // Screen position
};

// Constant buffer for texture handles
cbuffer Textures : register(b4)
{
	TextureHandle u_gbuffer0;
	TextureHandle u_gbuffer1;
	TextureHandle u_gbuffer2;
	TextureHandle u_gbuffer3;
	TextureHandle u_gbuffer_depth;
	TextureHandle u_shadowmap;
	TextureHandle u_shadow_atlas;
	TextureHandle u_reflection_probes;
};

// Vertex Shader: Generates position and UV coordinates for a fullscreen quad
VSOutput mainVS(uint vertexID : SV_VertexID)
{
	VSOutput output;
	output.position = fullscreenQuad(vertexID, output.uv); // Get position and UVs for the quad
	return output;
}

// Pixel Shader: Computes final color based on lighting and surface properties
float4 mainPS(VSOutput input) : SV_Target
{
	float ndc_depth; // Normalized device coordinates depth

    // Unpack surface data from G-buffers
	Surface surface = unpackSurface(input.uv,
                                    u_gbuffer0,
                                    u_gbuffer1,
                                    u_gbuffer2,
                                    u_gbuffer3,
                                    u_gbuffer_depth,
                                    ndc_depth);
    
    // Retrieve cluster information based on depth and position
	Cluster cluster = getCluster(ndc_depth, input.position.xy);
    
    // Compute lighting based on the cluster and surface properties
	float4 res;
	res.rgb = computeLighting(cluster,
                              surface,
                              Global_light_dir.xyz,
                              Global_light_color.rgb * Global_light_intensity,
                              u_shadowmap,
                              u_shadow_atlas,
                              u_reflection_probes,
                              input.position.xy);
    
	res.a = 1; // Set alpha to fully opaque
	return res; // Return final color
}