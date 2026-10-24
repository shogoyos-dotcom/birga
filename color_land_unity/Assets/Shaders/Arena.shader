Shader "ColorLand/ArenaShader"
{
    Properties
    {
        _IndexTex ("Index Texture (Ownership)", 2D) = "black" {}
        _PaletteTex ("Palette Texture", 2D) = "white" {}
        _GridSize ("Grid Size", Vector) = (100, 100, 0, 0)
        _BeachColor ("Beach Color", Color) = (0.99, 0.88, 0.28, 1)
        _UnclaimedColor ("Unclaimed Land Color", Color) = (0.92, 0.98, 0.95, 1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
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
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }

            // 4x4 Isotropic Radial Quartic Kernel (R=2.2, R^2=4.84)
            // Staircase chegaralarni butunlay yo'qotadi va qirg'oqdagi sariq bo'shliqlarni bartaraf etadi.
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
                            // R kanalida egalik qiymati
                            float4 c_tex = _IndexTex.Load(int3(c_pos, 0));
                            int owner = int(c_tex.r * 255.0 + 0.5);

                            // WATER (255) kataklar ovozdan butunlay chiqarib tashlanadi
                            if (owner != WATER)
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

                int win_owner = 0;
                float best_w = -1.0;

                for (int i = 0; i < num_u; i++)
                {
                    if (u_weights[i] > best_w)
                    {
                        best_w = u_weights[i];
                        win_owner = u_owners[i];
                    }
                }

                // Rang tanlash
                float3 color = _UnclaimedColor.rgb;
                if (win_owner == 0)
                {
                    color = _UnclaimedColor.rgb;
                }
                else
                {
                    // Palette_tex dan egasining rangini olish
                    float u = (float(win_owner) + 0.5) / 256.0;
                    color = _PaletteTex.Sample(sampler_PaletteTex, float2(u, 0.5)).rgb;
                }

                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }
}
