Shader "ColorLand/WaterShader"
{
    Properties
    {
        _DeepColor ("Deep Color", Color) = (0.02, 0.42, 0.76, 1.0)
        _ShallowColor ("Shallow Color", Color) = (0.08, 0.78, 0.90, 1.0)
        _FoamColor ("Foam Color", Color) = (0.96, 0.99, 1.0, 0.95)
        _WaveSpeed ("Wave Speed", Float) = 0.65
        _WaveScale ("Wave Scale", Float) = 0.15
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
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float t = _Time.y * _WaveSpeed;
                float2 uv = input.positionWS.xz * _WaveScale;

                // 2-layer animated cartoon wave pattern
                float w1 = sin(uv.x * 2.2 + t * 1.4) * cos(uv.y * 1.8 + t * 1.1);
                float w2 = sin((uv.x * 1.3 - uv.y * 1.9) + t * 0.9);
                float wave = (w1 * 0.6 + w2 * 0.4);

                float3 water = lerp(_DeepColor.rgb, _ShallowColor.rgb, 0.35 + 0.45 * wave);

                // Foam on wave crests
                float crest = smoothstep(0.42, 0.78, wave);
                water = lerp(water, _FoamColor.rgb, crest * 0.50);

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
                float3 worldPos : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float t = _Time.y * _WaveSpeed;
                float2 uv = i.worldPos.xz * _WaveScale;

                float w1 = sin(uv.x * 2.2 + t * 1.4) * cos(uv.y * 1.8 + t * 1.1);
                float w2 = sin((uv.x * 1.3 - uv.y * 1.9) + t * 0.9);
                float wave = (w1 * 0.6 + w2 * 0.4);

                float3 water = lerp(_DeepColor.rgb, _ShallowColor.rgb, 0.35 + 0.45 * wave);
                float crest = smoothstep(0.42, 0.78, wave);
                water = lerp(water, _FoamColor.rgb, crest * 0.50);

                return half4(water, 1.0);
            }
            ENDCG
        }
    }

    Fallback "Mobile/Diffuse"
}
