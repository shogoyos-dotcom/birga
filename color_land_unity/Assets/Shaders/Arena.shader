Shader "ColorLand/ArenaShader"
{
    Properties
    {
        _IndexTex ("Index Texture (Ownership)", 2D) = "black" {}
        _PaletteTex ("Palette Texture", 2D) = "white" {}
        _GridSize ("Grid Size", Vector) = (120, 120, 0, 0)
        _BeachColor ("Beach Color", Color) = (0.99, 0.88, 0.32, 1)
        _UnclaimedColor ("Unclaimed Land Color", Color) = (0.57, 0.88, 0.48, 1)
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
                float2 base = floor(p);
                float2 f = p - base;

                int2 b = int2(base);
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

                if (num_u == 0)
                {
                    return half4(_WaterColor.rgb, 1.0);
                }

                int win_owner = 0;
                float best_w = -1.0;
                float second_w = -1.0;
                int second_owner = 0;

                for (int i = 0; i < num_u; i++)
                {
                    if (u_weights[i] > best_w)
                    {
                        second_w = best_w;
                        second_owner = win_owner;
                        best_w = u_weights[i];
                        win_owner = u_owners[i];
                    }
                    else if (u_weights[i] > second_w)
                    {
                        second_w = u_weights[i];
                        second_owner = u_owners[i];
                    }
                }

                float3 color;
                if (win_owner == 0)
                {
                    color = _UnclaimedColor.rgb;
                    if (water_count > 0)
                    {
                        float beach_t = clamp((float)water_count / 5.0, 0.0, 1.0);
                        color = lerp(_UnclaimedColor.rgb, _BeachColor.rgb, beach_t);
                    }
                }
                else
                {
                    float u = (float(win_owner) + 0.5) / 256.0;
                    float3 owner_col = _PaletteTex.SampleLevel(sampler_PaletteTex, float2(u, 0.5), 0).rgb;

                    // Rim contour
                    float gap = (best_w - second_w) / max(best_w, 0.001);
                    float rim_t = smoothstep(0.0, 0.22, gap);
                    float3 rim_col = owner_col * 0.82;
                    color = lerp(rim_col, owner_col, rim_t);
                }

                // Subtle cartoon terrain variation
                float var = sin(cell_pos.x * 0.12) * cos(cell_pos.y * 0.12) * 0.035;
                color *= (0.98 + var);

                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }

    // ------------------------------------------------------------------
    // SubShader 2: Built-in Render Pipeline (Fallback & Mobile Forward)
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
                float2 base = floor(p);
                float2 f = p - base;

                int2 b = int2(base);
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

                if (num_u == 0)
                {
                    return half4(_WaterColor.rgb, 1.0);
                }

                int win_owner = 0;
                float best_w = -1.0;
                float second_w = -1.0;

                for (int idx = 0; idx < num_u; idx++)
                {
                    if (u_weights[idx] > best_w)
                    {
                        second_w = best_w;
                        best_w = u_weights[idx];
                        win_owner = u_owners[idx];
                    }
                    else if (u_weights[idx] > second_w)
                    {
                        second_w = u_weights[idx];
                    }
                }

                float3 color;
                if (win_owner == 0)
                {
                    color = _UnclaimedColor.rgb;
                    if (water_count > 0)
                    {
                        float beach_t = clamp((float)water_count / 5.0, 0.0, 1.0);
                        color = lerp(_UnclaimedColor.rgb, _BeachColor.rgb, beach_t);
                    }
                }
                else
                {
                    float u = (float(win_owner) + 0.5) / 256.0;
                    float3 owner_col = tex2Dlod(_PaletteTex, float4(u, 0.5, 0, 0)).rgb;

                    float gap = (best_w - second_w) / max(best_w, 0.001);
                    float rim_t = smoothstep(0.0, 0.22, gap);
                    float3 rim_col = owner_col * 0.82;
                    color = lerp(rim_col, owner_col, rim_t);
                }

                float var = sin(cell_pos.x * 0.12) * cos(cell_pos.y * 0.12) * 0.035;
                color *= (0.98 + var);

                return half4(color, 1.0);
            }
            ENDCG
        }
    }

    Fallback "Mobile/Diffuse"
}
