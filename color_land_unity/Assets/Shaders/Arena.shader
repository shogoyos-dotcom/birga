Shader "ColorLand/ArenaShader"
{
    Properties
    {
        _IndexTex ("Index Texture (Ownership)", 2D) = "black" {}
        _PaletteTex ("Palette Texture", 2D) = "white" {}
        _GridSize ("Grid Size", Vector) = (120, 120, 0, 0)
        _BeachColor ("Beach Color", Color) = (0.92, 0.84, 0.58, 1)
        _UnclaimedColor ("Unclaimed Land Color", Color) = (0.30, 0.62, 0.20, 1)
        _WaterColor ("Water Color", Color) = (0.04, 0.65, 0.82, 1)
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
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
                float3 posWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(posWS);
                output.uv = input.uv;
                output.positionWS = posWS;
                return output;
            }

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
                float total_water_w = 0.0;

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
                            float2 sample_uv = float2(_GridSize.x - 1 - c_pos.x + 0.5, _GridSize.y - 1 - c_pos.y + 0.5) / _GridSize.xy;
                            float4 c_tex = _IndexTex.SampleLevel(sampler_IndexTex, sample_uv, 0);
                            int owner = int(c_tex.r * 255.0 + 0.5);

                            if (owner == WATER)
                            {
                                total_water_w += w;
                            }
                            else
                            {
                                total_land_w += w;
                                int found = -1;
                                for (int k = 0; k < num_u; k++)
                                {
                                    if (u_owners[k] == owner) { found = k; break; }
                                }
                                if (found >= 0) u_weights[found] += w;
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

                // Perfectly smooth continuous land-vs-water density field
                float land_density = total_land_w / (total_land_w + total_water_w + 1e-5);
                if (land_density < 0.20)
                {
                    clip(-1);
                    return half4(0, 0, 0, 0);
                }

                float inv_tot = 1.0 / max(total_land_w, 1e-4);
                for (int k2 = 0; k2 < num_u; k2++) u_weights[k2] *= inv_tot;

                int best_idx = 0;
                for (int kb = 1; kb < num_u; kb++)
                {
                    if (u_weights[kb] > u_weights[best_idx]) best_idx = kb;
                }
                int win_owner = u_owners[best_idx];
                float best_w = u_weights[best_idx];

                int second_idx = -1;
                for (int ks = 0; ks < num_u; ks++)
                {
                    if (ks != best_idx && (second_idx < 0 || u_weights[ks] > u_weights[second_idx]))
                        second_idx = ks;
                }

                // Natural rich cartoon meadow grass gradient
                float2 land_uv = cell_pos * 0.08;
                float grad_t = 0.5 + 0.5 * sin(land_uv.x * 1.5 + land_uv.y * 1.1);
                float3 grass_col = lerp(float3(0.28, 0.68, 0.18), float3(0.38, 0.76, 0.22), grad_t);

                float3 shade_best = grass_col;
                if (win_owner == 1) shade_best = float3(0.06, 0.44, 0.90);      // Royal Blue (Player)
                else if (win_owner == 2) shade_best = float3(0.88, 0.16, 0.22); // Crimson Red (Berlin)
                else if (win_owner == 3) shade_best = float3(0.96, 0.74, 0.08); // Golden Amber (Dubai)
                else if (win_owner > 0)
                {
                    float u = (float(win_owner) + 0.5) / 256.0;
                    shade_best = _PaletteTex.SampleLevel(sampler_PaletteTex, float2(u, 0.5), 0).rgb;
                }

                float3 final_col = shade_best;

                int sec_safe = clamp(second_idx, 0, 7);
                int sec_owner = (second_idx >= 0) ? u_owners[sec_safe] : 0;
                float sec_w = (second_idx >= 0) ? u_weights[sec_safe] : 0.0;

                if (second_idx >= 0 && sec_w > 0.001)
                {
                    float gap = best_w - sec_w;
                    float3 shade_sec = grass_col;
                    if (sec_owner == 1) shade_sec = float3(0.06, 0.44, 0.90);
                    else if (sec_owner == 2) shade_sec = float3(0.88, 0.16, 0.22);
                    else if (sec_owner == 3) shade_sec = float3(0.96, 0.74, 0.08);
                    else if (sec_owner > 0)
                    {
                        float u2 = (float(sec_owner) + 0.5) / 256.0;
                        shade_sec = _PaletteTex.SampleLevel(sampler_PaletteTex, float2(u2, 0.5), 0).rgb;
                    }

                    float fw = max(fwidth(gap), 0.001);
                    float edge_t = saturate(0.5 + 0.5 * gap / fw);
                    final_col = lerp(shade_sec, shade_best, edge_t);
                }

                // Seamless golden beach shoreline & white wave foam
                if (win_owner == 0)
                {
                    float beach_t = smoothstep(0.68, 0.23, land_density);
                    final_col = lerp(final_col, float3(0.96, 0.88, 0.58), beach_t * 0.90);
                    float foam = smoothstep(0.20, 0.25, land_density) * smoothstep(0.33, 0.25, land_density) * 1.8;
                    final_col = lerp(final_col, float3(1.0, 1.0, 1.0), saturate(foam));
                }

                // Sunlight & toon lighting
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                float3 normal = normalize(float3(-cos(cell_pos.x * 0.14) * 0.06, 1.0, -cos(cell_pos.y * 0.14) * 0.06));
                float NdotL = saturate(dot(normal, lightDir));
                float toon = smoothstep(0.35, 0.55, NdotL) * 0.30 + 0.70;
                float3 lit_col = final_col * (mainLight.color * toon + unity_AmbientSky.rgb * 0.35);

                // Glossy territory specular sheen
                if (win_owner > 0)
                {
                    float3 viewDir = normalize(GetWorldSpaceNormalizeViewDir(input.positionWS));
                    float3 halfVec = normalize(lightDir + viewDir);
                    float spec = pow(saturate(dot(normal, halfVec)), 20.0) * 0.35;
                    lit_col += mainLight.color * spec;
                }

                // -------------------------------------------------------------
                // RADIANT ELECTRIC NEON BORDER (Silliq hudud chegaralari) - 1-TO-1 REFERENCE
                // -------------------------------------------------------------
                int glow_owner = 0;
                float border_w = 0.0;

                if (win_owner > 0 && second_idx >= 0)
                {
                    glow_owner = win_owner;
                    border_w = sec_w;
                }
                else if (win_owner == 0 && second_idx >= 0 && sec_owner > 0)
                {
                    glow_owner = sec_owner;
                    border_w = sec_w;
                }

                if (glow_owner > 0 && border_w > 0.01)
                {
                    float3 neon_col;
                    if (glow_owner == 1) neon_col = float3(0.00, 0.95, 1.00);      // Radiant Electric Cyan (Tashkent/SHO)
                    else if (glow_owner == 2) neon_col = float3(1.00, 0.16, 0.44); // Radiant Neon Coral-Pink (Berlin)
                    else if (glow_owner == 3) neon_col = float3(1.00, 0.92, 0.10); // Radiant Lemon Sun Gold (Dubai)
                    else neon_col = float3(0.20, 1.00, 0.45);

                    float prox = saturate(border_w / 0.45);
                    float halo = smoothstep(0.01, 0.70, prox);
                    float core = smoothstep(0.12, 0.75, prox);

                    float3 rim = lerp(neon_col, float3(1.0, 1.0, 1.0), core * 0.94);
                    lit_col = lerp(lit_col, rim, halo * 0.92) + rim * (core * 1.65) + neon_col * (halo * 0.65);
                }

                return half4(lit_col, 1.0);
            }
            ENDHLSL
        }
    }

    // ------------------------------------------------------------------
    // SubShader 2: Built-in Render Pipeline (Shadows & Full Features)
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
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

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
                float3 worldPos : TEXCOORD1;
                SHADOW_COORDS(2)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                TRANSFER_SHADOW(o);
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
                float total_water_w = 0.0;

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
                            float2 sample_uv = float2(_GridSize.x - 1 - c_pos.x + 0.5, _GridSize.y - 1 - c_pos.y + 0.5) / _GridSize.xy;
                            float4 c_tex = tex2Dlod(_IndexTex, float4(sample_uv, 0, 0));
                            int owner = int(c_tex.r * 255.0 + 0.5);

                            if (owner == WATER)
                            {
                                total_water_w += w;
                            }
                            else
                            {
                                total_land_w += w;
                                int found = -1;
                                for (int k = 0; k < num_u; k++)
                                {
                                    if (u_owners[k] == owner) { found = k; break; }
                                }
                                if (found >= 0) u_weights[found] += w;
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

                // Continuous smooth land density field (zero staircase contouring)
                float land_density = total_land_w / (total_land_w + total_water_w + 1e-5);
                if (land_density < 0.20)
                {
                    clip(-1);
                    return half4(0, 0, 0, 0);
                }

                float inv_tot = 1.0 / max(total_land_w, 1e-4);
                for (int k2 = 0; k2 < num_u; k2++) u_weights[k2] *= inv_tot;

                int best_idx = 0;
                for (int kb = 1; kb < num_u; kb++)
                {
                    if (u_weights[kb] > u_weights[best_idx]) best_idx = kb;
                }
                int win_owner = u_owners[best_idx];
                float best_w = u_weights[best_idx];

                int second_idx = -1;
                for (int ks = 0; ks < num_u; ks++)
                {
                    if (ks != best_idx && (second_idx < 0 || u_weights[ks] > u_weights[second_idx]))
                        second_idx = ks;
                }

                // Natural rich cartoon meadow grass gradient
                float2 land_uv = cell_pos * 0.08;
                float grad_t = 0.5 + 0.5 * sin(land_uv.x * 1.5 + land_uv.y * 1.1);
                float3 grass_col = lerp(float3(0.28, 0.68, 0.18), float3(0.38, 0.76, 0.22), grad_t);

                float3 shade_best = grass_col;
                if (win_owner == 1) shade_best = float3(0.06, 0.44, 0.90);      // Royal Blue (Player)
                else if (win_owner == 2) shade_best = float3(0.88, 0.16, 0.22); // Crimson Red (Berlin)
                else if (win_owner == 3) shade_best = float3(0.96, 0.74, 0.08); // Golden Amber (Dubai)
                else if (win_owner > 0)
                {
                    float u = (float(win_owner) + 0.5) / 256.0;
                    shade_best = tex2Dlod(_PaletteTex, float4(u, 0.5, 0, 0)).rgb;
                }

                float3 final_col = shade_best;

                int sec_safe = clamp(second_idx, 0, 7);
                int sec_owner = (second_idx >= 0) ? u_owners[sec_safe] : 0;
                float sec_w = (second_idx >= 0) ? u_weights[sec_safe] : 0.0;

                if (second_idx >= 0 && sec_w > 0.001)
                {
                    float gap = best_w - sec_w;
                    float3 shade_sec = grass_col;
                    if (sec_owner == 1) shade_sec = float3(0.06, 0.44, 0.90);
                    else if (sec_owner == 2) shade_sec = float3(0.88, 0.16, 0.22);
                    else if (sec_owner == 3) shade_sec = float3(0.96, 0.74, 0.08);
                    else if (sec_owner > 0)
                    {
                        float u2 = (float(sec_owner) + 0.5) / 256.0;
                        shade_sec = tex2Dlod(_PaletteTex, float4(u2, 0.5, 0, 0)).rgb;
                    }

                    float fw = max(fwidth(gap), 0.001);
                    float edge_t = saturate(0.5 + 0.5 * gap / fw);
                    final_col = lerp(shade_sec, shade_best, edge_t);
                }

                // Seamless golden beach shoreline & white wave foam
                if (win_owner == 0)
                {
                    float beach_t = smoothstep(0.68, 0.23, land_density);
                    final_col = lerp(final_col, float3(0.96, 0.88, 0.58), beach_t * 0.90);
                    float foam = smoothstep(0.20, 0.25, land_density) * smoothstep(0.33, 0.25, land_density) * 1.8;
                    final_col = lerp(final_col, float3(1.0, 1.0, 1.0), saturate(foam));
                }

                // Direct lighting with soft shadows
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                if (dot(lightDir, lightDir) < 0.1) lightDir = normalize(float3(0.35, 0.85, -0.40));
                float3 lightCol = _LightColor0.rgb;
                if (dot(lightCol, lightCol) < 0.1) lightCol = float3(1.0, 0.98, 0.92);
                float3 ambSky = unity_AmbientSky.rgb;
                if (dot(ambSky, ambSky) < 0.1) ambSky = float3(0.40, 0.52, 0.38);

                UNITY_LIGHT_ATTENUATION(shadow_atten, i, i.worldPos);

                float3 normal = normalize(float3(-cos(cell_pos.x * 0.14) * 0.06, 1.0, -cos(cell_pos.y * 0.14) * 0.06));
                float NdotL = saturate(dot(normal, lightDir));
                float toon = smoothstep(0.35, 0.55, NdotL) * 0.30 + 0.70;
                float3 lit_col = final_col * (lightCol * (toon * shadow_atten) + ambSky * 0.35);

                // Glossy territory specular sheen
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                if (win_owner > 0)
                {
                    float3 halfVec = normalize(lightDir + viewDir);
                    float spec = pow(saturate(dot(normal, halfVec)), 20.0) * 0.35 * shadow_atten;
                    lit_col += lightCol * spec;
                }

                // -------------------------------------------------------------
                // RADIANT ELECTRIC NEON BORDER (Silliq hudud chegaralari) - 1-TO-1 REFERENCE
                // -------------------------------------------------------------
                int glow_owner = 0;
                float border_w = 0.0;

                if (win_owner > 0 && second_idx >= 0)
                {
                    glow_owner = win_owner;
                    border_w = sec_w;
                }
                else if (win_owner == 0 && second_idx >= 0 && sec_owner > 0)
                {
                    glow_owner = sec_owner;
                    border_w = sec_w;
                }

                if (glow_owner > 0 && border_w > 0.01)
                {
                    float3 neon_col;
                    if (glow_owner == 1) neon_col = float3(0.00, 0.95, 1.00);      // Radiant Electric Cyan (Tashkent/SHO)
                    else if (glow_owner == 2) neon_col = float3(1.00, 0.16, 0.44); // Radiant Neon Coral-Pink (Berlin)
                    else if (glow_owner == 3) neon_col = float3(1.00, 0.92, 0.10); // Radiant Lemon Sun Gold (Dubai)
                    else neon_col = float3(0.20, 1.00, 0.45);

                    float prox = saturate(border_w / 0.45);
                    float halo = smoothstep(0.01, 0.70, prox);
                    float core = smoothstep(0.12, 0.75, prox);

                    float3 rim = lerp(neon_col, float3(1.0, 1.0, 1.0), core * 0.94);
                    lit_col = lerp(lit_col, rim, halo * 0.92) + rim * (core * 1.65) + neon_col * (halo * 0.65);
                }

                return half4(lit_col, 1.0);
            }
            ENDCG
        }
    }

    Fallback "Mobile/Diffuse"
}
