Shader "ColorLand/CartoonLit"
{
    Properties
    {
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo Texture", 2D) = "white" {}
        _RimColor ("Rim Color", Color) = (1, 1, 1, 0.35)
        _RimPower ("Rim Power", Range(0.5, 8.0)) = 3.0
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
                float3 normalOS     : NORMAL;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float3 normalWS     : TEXCOORD0;
                float3 viewDirWS    : TEXCOORD1;
                float2 uv           : TEXCOORD2;
            };

            Texture2D _MainTex;
            SamplerState sampler_MainTex;

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _RimColor;
                float _RimPower;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                float3 posWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(posWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.viewDirWS = GetWorldSpaceNormalizeViewDir(posWS);
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                Light mainLight = GetMainLight();
                float3 normal = normalize(input.normalWS);
                float3 view = normalize(input.viewDirWS);

                float NdotL = saturate(dot(normal, mainLight.direction));
                float toon = smoothstep(0.40, 0.55, NdotL) * 0.35 + 0.65;

                float rim = 1.0 - saturate(dot(view, normal));
                rim = pow(rim, _RimPower);

                float4 texCol = _MainTex.Sample(sampler_MainTex, input.uv);
                float3 baseCol = _Color.rgb * texCol.rgb;
                float3 litCol = baseCol * (mainLight.color * toon + unity_AmbientSky.rgb * 0.5);
                litCol += _RimColor.rgb * rim * _RimColor.a;

                return half4(litCol, _Color.a * texCol.a);
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
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _Color;
            float4 _RimColor;
            float _RimPower;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float3 posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normalWS = UnityObjectToWorldNormal(v.normal);
                o.viewDirWS = normalize(_WorldSpaceCameraPos - posWS);
                o.uv = v.uv;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float3 normal = normalize(i.normalWS);
                float3 view = normalize(i.viewDirWS);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                float NdotL = saturate(dot(normal, lightDir));
                float toon = smoothstep(0.40, 0.55, NdotL) * 0.35 + 0.65;

                float rim = 1.0 - saturate(dot(view, normal));
                rim = pow(rim, _RimPower);

                float4 texCol = tex2D(_MainTex, i.uv);
                float3 baseCol = _Color.rgb * texCol.rgb;
                float3 litCol = baseCol * (_LightColor0.rgb * toon + unity_AmbientSky.rgb * 0.5);
                litCol += _RimColor.rgb * rim * _RimColor.a;

                return half4(litCol, _Color.a * texCol.a);
            }
            ENDCG
        }
    }

    Fallback "Mobile/Diffuse"
}
