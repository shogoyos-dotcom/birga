Shader "ColorLand/WaterShader"
{
    Properties
    {
        _DeepColor ("Deep Color", Color) = (0.02, 0.40, 0.78, 1.0)
        _ShallowColor ("Shallow Color", Color) = (0.05, 0.82, 0.90, 1.0)
        _FoamColor ("Foam Color", Color) = (0.96, 1.0, 1.0, 0.95)
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
                float t = _Time.y * _WaveSpeed;
                float w = sin(posWS.x * 0.15 + t + 0.7) * cos(posWS.z * 0.15 + t * 0.8 + 0.3) * 0.05;
                posWS.y += w;

                output.positionWS = posWS;
                output.positionCS = TransformWorldToHClip(posWS);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float t = _Time.y * _WaveSpeed;
                float2 uv = input.positionWS.xz * _WaveScale;

                // Smooth organic water caustics and radiant turquoise gradients
                float w1 = sin(uv.x * 2.2 + t * 1.4 + 1.2) * cos(uv.y * 1.8 + t * 1.1 + 0.8);
                float w2 = sin((uv.x * 1.3 - uv.y * 1.9) + t * 0.9 + 2.1);
                float w3 = cos(uv.x * 2.8 + uv.y * 2.2 - t * 1.5);
                float wave = (w1 * 0.50 + w2 * 0.32 + w3 * 0.18) * 0.5 + 0.5;

                // Crystal clear tropical azure to radiant turquoise depth transition
                float3 water = lerp(_DeepColor.rgb, _ShallowColor.rgb, pow(wave, 1.3));

                // Soft sun glints and surface caustics (zero harsh polka dots)
                float glint = pow(wave, 5.0) * 0.45;
                water += _FoamColor.rgb * glint;

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
                float w = sin(posWS.x * 0.15 + t + 0.7) * cos(posWS.z * 0.15 + t * 0.8 + 0.3) * 0.05;
                posWS.y += w;

                o.pos = mul(UNITY_MATRIX_VP, float4(posWS, 1.0));
                o.positionWS = posWS;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float t = _Time.y * _WaveSpeed;
                float2 uv = i.positionWS.xz * _WaveScale;

                // Smooth organic water caustics and radiant turquoise gradients
                float w1 = sin(uv.x * 2.2 + t * 1.4 + 1.2) * cos(uv.y * 1.8 + t * 1.1 + 0.8);
                float w2 = sin((uv.x * 1.3 - uv.y * 1.9) + t * 0.9 + 2.1);
                float w3 = cos(uv.x * 2.8 + uv.y * 2.2 - t * 1.5);
                float wave = (w1 * 0.50 + w2 * 0.32 + w3 * 0.18) * 0.5 + 0.5;

                // Crystal clear tropical azure to radiant turquoise depth transition
                float3 water = lerp(_DeepColor.rgb, _ShallowColor.rgb, pow(wave, 1.3));

                // Soft sun glints and surface caustics (zero harsh polka dots)
                float glint = pow(wave, 5.0) * 0.45;
                water += _FoamColor.rgb * glint;

                return half4(water, 1.0);
            }
            ENDCG
        }
    }

    Fallback "Mobile/Diffuse"
}
