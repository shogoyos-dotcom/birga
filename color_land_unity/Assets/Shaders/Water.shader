Shader "ColorLand/WaterShader"
{
    Properties
    {
        _DeepColor ("Deep Color", Color) = (0.01, 0.35, 0.72, 1.0)
        _ShallowColor ("Shallow Color", Color) = (0.04, 0.75, 0.88, 1.0)
        _FoamColor ("Foam Color", Color) = (0.95, 0.99, 1.0, 0.95)
        _WaveSpeed ("Wave Speed", Float) = 0.75
        _WaveScale ("Wave Scale", Float) = 0.18
    }

    // ------------------------------------------------------------------
    // SubShader 1: Universal Render Pipeline (URP)
    // ------------------------------------------------------------------
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry-1" }
        LOD 150

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
                float3 positionWS   : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _DeepColor;
                float4 _ShallowColor;
                float4 _FoamColor;
                float _WaveSpeed;
                float _WaveScale;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                float3 posWS = TransformObjectToWorld(input.positionOS.xyz);
                
                // Subtle cartoon physical vertical wave bobbing
                float t = _Time.y * _WaveSpeed;
                float w = sin(posWS.x * 0.15 + t) * cos(posWS.z * 0.15 + t * 0.8) * 0.04;
                posWS.y += w;

                output.positionWS = posWS;
                output.positionCS = TransformWorldToHClip(posWS);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float t = _Time.y * _WaveSpeed;
                float2 uv = input.positionWS.xz * _WaveScale;

                // 3-layer rich tropical wave motion
                float w1 = sin(uv.x * 2.2 + t * 1.4) * cos(uv.y * 1.8 + t * 1.1);
                float w2 = sin((uv.x * 1.3 - uv.y * 1.9) + t * 0.9);
                float w3 = cos(uv.x * 2.8 + uv.y * 2.2 - t * 1.5);
                float wave = (w1 * 0.50 + w2 * 0.32 + w3 * 0.18);

                // Caribbean deep blue to turquoise gradient
                float3 water = lerp(_DeepColor.rgb, _ShallowColor.rgb, 0.38 + 0.44 * wave);

                // White foam crests
                float crest = smoothstep(0.40, 0.74, wave);
                water = lerp(water, _FoamColor.rgb, crest * 0.55);

                // Subtle cartoon specular glint
                float glint = pow(max(0.0, wave), 4.0) * 0.18;
                water += float3(glint, glint, glint);

                return half4(water, 1.0);
            }
            ENDHLSL
        }
    }

    // ------------------------------------------------------------------
    // SubShader 2: Built-in Render Pipeline
    // ------------------------------------------------------------------
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry-1" }
        LOD 150

        Pass
        {
            Name "ForwardBase"
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"

            float4 _DeepColor;
            float4 _ShallowColor;
            float4 _FoamColor;
            float _WaveSpeed;
            float _WaveScale;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 positionWS : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                float3 posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
                float t = _Time.y * _WaveSpeed;
                float w = sin(posWS.x * 0.15 + t) * cos(posWS.z * 0.15 + t * 0.8) * 0.04;
                posWS.y += w;

                o.pos = mul(UNITY_MATRIX_VP, float4(posWS, 1.0));
                o.positionWS = posWS;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float t = _Time.y * _WaveSpeed;
                float2 uv = i.positionWS.xz * _WaveScale;

                float w1 = sin(uv.x * 2.2 + t * 1.4) * cos(uv.y * 1.8 + t * 1.1);
                float w2 = sin((uv.x * 1.3 - uv.y * 1.9) + t * 0.9);
                float w3 = cos(uv.x * 2.8 + uv.y * 2.2 - t * 1.5);
                float wave = (w1 * 0.50 + w2 * 0.32 + w3 * 0.18);

                float3 water = lerp(_DeepColor.rgb, _ShallowColor.rgb, 0.38 + 0.44 * wave);

                float crest = smoothstep(0.40, 0.74, wave);
                water = lerp(water, _FoamColor.rgb, crest * 0.55);

                float glint = pow(max(0.0, wave), 4.0) * 0.18;
                water += float3(glint, glint, glint);

                return half4(water, 1.0);
            }
            ENDCG
        }
    }

    Fallback "Mobile/Diffuse"
}
