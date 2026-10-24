Shader "ColorLand/ArenaShader"
{
    Properties
    {
        _IndexTex ("Index Texture (Ownership)", 2D) = "black" {}
        _PaletteTex ("Palette Texture", 2D) = "white" {}
        _GridSize ("Grid Size", Vector) = (120, 120, 0, 0)
        _BeachColor ("Beach Color", Color) = (0.99, 0.88, 0.42, 1)
        _UnclaimedColor ("Unclaimed Land Color", Color) = (0.50, 0.82, 0.32, 1)
        _WaterColor ("Water Color", Color) = (0.04, 0.48, 0.82, 1)
    }

    // ------------------------------------------------------------------
    // SubShader 1: Universal Render Pipeline (URP)
    // ------------------------------------------------------------------
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        LOD 200

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            Texture2D _IndexTex;
            SamplerState sampler_IndexTex;

            Texture2D _PaletteTex;
            SamplerState sampler_PaletteTex;

            CBUFFER_START(UnityPerMaterial)
                float4 _GridSize;
                float4 _BeachColor;
                float4 _UnclaimedColor;
                float4 _WaterColor;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }

            // 4x4 Isotropic Radial Quartic Kernel (R = 2.2, R^2 = 4.84)
            half4 frag(Varyings input) : SV_Target
            {
                float2 cell_pos = input.uv * _GridSize.xy;
                float2 p = cell_pos - 0.5;
                float2 base_cell = floor(p);
                float2 f = p - base_cell;

                int2 b = int2(base_cell);
                int2 max_c = int2(_GridSize.xy) - int2(1, 1);

                const float R2 = 4.84;
                const float INV_R2 = 1.0 / 4.84;
                const int WATER = 255;

                int u_owners[8];
                float u_weights[8];
                int num_u = 0;
                float total_land_w = 0.0;
                int water_count = 0;

                for (int dy = -1; dy <= 2; dy++)
                {
                    for (int dx = -1; dx <= 2; dx++)
                    {
                        float2 delta = float2(dx, dy) - f;
                        float r2 = dot(delta, delta);
                        if (r2 < R2)
                        {
                            float q = 1.0 - r2 * INV_R2;
                            float w = q * q;

                            int2 c_pos = clamp(b + int2(dx, dy), int2(0, 0), max_c);
                            float2 sample_uv = (float2(c_pos) + 0.5) / _GridSize.xy;
                            float4 c_tex = _IndexTex.SampleLevel(sampler_IndexTex, sample_uv, 0);
                            int owner = int(c_tex.r * 255.0 + 0.5);

                            if (owner == WATER)
                            {
                                water_count++;
                            }
                            else
                            {
                                total_land_w += w;
                                int found = -1;
                                for (int k = 0; k < num_u; k++)
                                {
                                    if (u_owners[k] == owner)
                                    {
                                        found = k;
                                        break;
                                    }
                                }
                                if (found >= 0)
                                {
                                    u_weights[found] += w;
                                }
                                else if (num_u < 8)
                                {
                                    u_owners[num_u] = owner;
                                    u_weights[num_u] = w;
                                    num_u++;
                                }
                            }
                        }
                    }
                }

                if (num_u == 0 || total_land_w < 0.0001)
                {
                    return half4(_WaterColor.rgb, 1.0);
                }

                // Normalize weights so boundaries have consistent curvature everywhere
                float inv_tot = 1.0 / total_land_w;
                for (int k = 0; k < num_u; k++)
                {
                    u_weights[k] *= inv_tot;
                }

                int best_idx = 0;
                for (int k = 1; k < num_u; k++)
                {
                    if (u_weights[k] > u_weights[best_idx])
                    {
                        best_idx = k;
                    }
                }
                int win_owner = u_owners[best_idx];
                float best_w = u_weights[best_idx];

                int second_idx = -1;
                for (int k = 0; k < num_u; k++)
                {
                    if (k != best_idx && (second_idx < 0 || u_weights[k] > u_weights[second_idx]))
                    {
                        second_idx = k;
                    }
                }

                // Lush cartoon grass gradient with subtle elevation shading
                float2 land_uv = cell_pos * 0.08;
                float grad_t = 0.5 + 0.5 * sin(land_uv.x * 1.5 + land_uv.y * 1.1);
                float3 land_col = lerp(float3(0.46, 0.80, 0.28), float3(0.56, 0.88, 0.36), grad_t);

                float3 shade_best;
                if (win_owner == 0)
                {
                    shade_best = land_col;
                }
                else
                {
                    float u = (float(win_owner) + 0.5) / 256.0;
                    float3 owner_col = _PaletteTex.SampleLevel(sampler_PaletteTex, float2(u, 0.5), 0).rgb;
                    shade_best = owner_col;
                }

                float3 final_col = shade_best;

                if (second_idx >= 0 && u_weights[second_idx] > 0.001)
                {
                    int sec_owner = u_owners[second_idx];
                    float sec_w = u_weights[second_idx];
                    float gap = best_w - sec_w;

                    // Rim contour for primary owner
                    const float RIM = 0.35;
                    if (win_owner > 0 && gap < RIM)
                    {
                        float3 rim_col = shade_best * 0.78;
                        shade_best = lerp(rim_col, shade_best, smoothstep(0.0, RIM, gap));
                    }

                    float3 shade_sec;
                    if (sec_owner == 0)
                    {
                        shade_sec = land_col;
                    }
                    else
                    {
                        float u2 = (float(sec_owner) + 0.5) / 256.0;
                        float3 sec_col = _PaletteTex.SampleLevel(sampler_PaletteTex, float2(u2, 0.5), 0).rgb;
                        shade_sec = sec_col;
                        if (gap < RIM)
                        {
                            float3 rim2 = sec_col * 0.78;
                            shade_sec = lerp(rim2, shade_sec, smoothstep(0.0, RIM, gap));
                        }
                    }

                    // Pixel-perfect antialiased smooth contour (zero staircase)
                    float fw = max(fwidth(gap), 0.001);
                    float edge_t = saturate(0.5 + 0.5 * gap / fw);
                    final_col = lerp(shade_sec, shade_best, edge_t);
                }

                // Coastline beach sand transition (ONLY on unclaimed land)
                if (win_owner == 0 && water_count > 0)
                {
                    float beach_t = saturate((float)water_count / 6.0);
                    final_col = lerp(final_col, _BeachColor.rgb, beach_t);
                }

                // Soft rolling hills micro-relief
                float relief = sin(cell_pos.x * 0.14) * cos(cell_pos.y * 0.14) * 0.032;
                final_col *= (0.98 + relief);

                return half4(final_col, 1.0);
            }
            ENDHLSL
        }
    }

    // ------------------------------------------------------------------
    // SubShader 2: Built-in Render Pipeline
    // ------------------------------------------------------------------
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200

        Pass
        {
            Name "ForwardBase"
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"

            sampler2D _IndexTex;
            sampler2D _PaletteTex;
            float4 _GridSize;
            float4 _BeachColor;
            float4 _UnclaimedColor;
            float4 _WaterColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float2 cell_pos = i.uv * _GridSize.xy;
                float2 p = cell_pos - 0.5;
                float2 base_cell = floor(p);
                float2 f = p - base_cell;

                int2 b = int2(base_cell);
                int2 max_c = int2(_GridSize.xy) - int2(1, 1);

                const float R2 = 4.84;
                const float INV_R2 = 1.0 / 4.84;
                const int WATER = 255;

                int u_owners[8];
                float u_weights[8];
                int num_u = 0;
                float total_land_w = 0.0;
                int water_count = 0;

                for (int dy = -1; dy <= 2; dy++)
                {
                    for (int dx = -1; dx <= 2; dx++)
                    {
                        float2 delta = float2(dx, dy) - f;
                        float r2 = dot(delta, delta);
                        if (r2 < R2)
                        {
                            float q = 1.0 - r2 * INV_R2;
                            float w = q * q;

                            int2 c_pos = clamp(b + int2(dx, dy), int2(0, 0), max_c);
                            float2 sample_uv = (float2(c_pos) + 0.5) / _GridSize.xy;
                            float4 c_tex = tex2Dlod(_IndexTex, float4(sample_uv, 0, 0));
                            int owner = int(c_tex.r * 255.0 + 0.5);

                            if (owner == WATER)
                            {
                                water_count++;
                            }
                            else
                            {
                                total_land_w += w;
                                int found = -1;
                                for (int k = 0; k < num_u; k++)
                                {
                                    if (u_owners[k] == owner)
                                    {
                                        found = k;
                                        break;
                                    }
                                }
                                if (found >= 0)
                                {
                                    u_weights[found] += w;
                                }
                                else if (num_u < 8)
                                {
                                    u_owners[num_u] = owner;
                                    u_weights[num_u] = w;
                                    num_u++;
                                }
                            }
                        }
                    }
                }

                if (num_u == 0 || total_land_w < 0.0001)
                {
                    return half4(_WaterColor.rgb, 1.0);
                }

                float inv_tot = 1.0 / total_land_w;
                for (int k = 0; k < num_u; k++)
                {
                    u_weights[k] *= inv_tot;
                }

                int best_idx = 0;
                for (int k = 1; k < num_u; k++)
                {
                    if (u_weights[k] > u_weights[best_idx])
                    {
                        best_idx = k;
                    }
                }
                int win_owner = u_owners[best_idx];
                float best_w = u_weights[best_idx];

                int second_idx = -1;
                for (int k = 0; k < num_u; k++)
                {
                    if (k != best_idx && (second_idx < 0 || u_weights[k] > u_weights[second_idx]))
                    {
                        second_idx = k;
                    }
                }

                float2 land_uv = cell_pos * 0.08;
                float grad_t = 0.5 + 0.5 * sin(land_uv.x * 1.5 + land_uv.y * 1.1);
                float3 land_col = lerp(float3(0.46, 0.80, 0.28), float3(0.56, 0.88, 0.36), grad_t);

                float3 shade_best;
                if (win_owner == 0)
                {
                    shade_best = land_col;
                }
                else
                {
                    float u = (float(win_owner) + 0.5) / 256.0;
                    float3 owner_col = tex2Dlod(_PaletteTex, float4(u, 0.5, 0, 0)).rgb;
                    shade_best = owner_col;
                }

                float3 final_col = shade_best;

                if (second_idx >= 0 && u_weights[second_idx] > 0.001)
                {
                    int sec_owner = u_owners[second_idx];
                    float sec_w = u_weights[second_idx];
                    float gap = best_w - sec_w;

                    const float RIM = 0.35;
                    if (win_owner > 0 && gap < RIM)
                    {
                        float3 rim_col = shade_best * 0.78;
                        shade_best = lerp(rim_col, shade_best, smoothstep(0.0, RIM, gap));
                    }

                    float3 shade_sec;
                    if (sec_owner == 0)
                    {
                        shade_sec = land_col;
                    }
                    else
                    {
                        float u2 = (float(sec_owner) + 0.5) / 256.0;
                        float3 sec_col = tex2Dlod(_PaletteTex, float4(u2, 0.5, 0, 0)).rgb;
                        shade_sec = sec_col;
                        if (gap < RIM)
                        {
                            float3 rim2 = sec_col * 0.78;
                            shade_sec = lerp(rim2, shade_sec, smoothstep(0.0, RIM, gap));
                        }
                    }

                    float fw = max(fwidth(gap), 0.001);
                    float edge_t = saturate(0.5 + 0.5 * gap / fw);
                    final_col = lerp(shade_sec, shade_best, edge_t);
                }

                if (win_owner == 0 && water_count > 0)
                {
                    float beach_t = saturate((float)water_count / 6.0);
                    final_col = lerp(final_col, _BeachColor.rgb, beach_t);
                }

                float relief = sin(cell_pos.x * 0.14) * cos(cell_pos.y * 0.14) * 0.032;
                final_col *= (0.98 + relief);

                return half4(final_col, 1.0);
            }
            ENDCG
        }
    }

    Fallback "Mobile/Diffuse"
}
