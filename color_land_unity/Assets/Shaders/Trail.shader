Shader "ColorLand/TrailShader"
{
    Properties
    {
        _Color ("Trail Color", Color) = (1, 1, 1, 1)
        _DangerColor ("Danger Color", Color) = (1, 0.15, 0.15, 1)
        _DangerFlash ("Danger Flash", Range(0, 1)) = 0.0
    }

    // ------------------------------------------------------------------
    // SubShader 1: Universal Render Pipeline (URP)
    // ------------------------------------------------------------------
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _DangerColor;
                float _DangerFlash;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.color = input.color;
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 baseCol = _Color.rgb * input.color.rgb;
                float3 col = lerp(baseCol, _DangerColor.rgb, _DangerFlash);

                // Edge contour
                float edge = abs(input.uv.y - 0.5) * 2.0;
                float border = smoothstep(0.70, 0.95, edge);
                col = lerp(col, float3(1, 1, 1), border * 0.40);

                return half4(col, _Color.a * input.color.a);
            }
            ENDHLSL
        }
    }

    // ------------------------------------------------------------------
    // SubShader 2: Built-in Render Pipeline
    // ------------------------------------------------------------------
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            Name "Unlit"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "UnityCG.cginc"

            float4 _Color;
            float4 _DangerColor;
            float _DangerFlash;

            struct appdata
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                o.uv = v.uv;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float3 baseCol = _Color.rgb * i.color.rgb;
                float3 col = lerp(baseCol, _DangerColor.rgb, _DangerFlash);

                float edge = abs(i.uv.y - 0.5) * 2.0;
                float border = smoothstep(0.70, 0.95, edge);
                col = lerp(col, float3(1, 1, 1), border * 0.40);

                return half4(col, _Color.a * i.color.a);
            }
            ENDCG
        }
    }

    Fallback "Mobile/Particles/Alpha Blended"
}
