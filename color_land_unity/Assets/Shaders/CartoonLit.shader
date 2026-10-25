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
                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float3 normalWS     : TEXCOORD0;
                float3 viewDirWS    : TEXCOORD1;
                float4 color        : COLOR;
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
                output.color = input.color;
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

                float3 halfVector = normalize(mainLight.direction + view);
                float NdotH = saturate(dot(normal, halfVector));
                float spec = smoothstep(0.70, 0.78, pow(NdotH, 24.0)) * 0.45;

                float4 texCol = _MainTex.Sample(sampler_MainTex, input.uv);
                float3 vCol = any(input.color.rgb) ? input.color.rgb : float3(1.0, 1.0, 1.0);
                float3 baseCol = _Color.rgb * texCol.rgb * vCol;
                float3 litCol = baseCol * (mainLight.color * toon + unity_AmbientSky.rgb * 0.5);
                litCol += _RimColor.rgb * rim * _RimColor.a;
                litCol += mainLight.color * spec;

                return half4(litCol, _Color.a * texCol.a * (any(input.color.rgb) ? input.color.a : 1.0));
            }
            ENDHLSL
        }
    }

    // ------------------------------------------------------------------
    // SubShader 2: Built-in Render Pipeline (Shadows & Plastic Sheen)
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

            sampler2D _MainTex;
            float4 _Color;
            float4 _RimColor;
            float _RimPower;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 color  : COLOR;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos        : SV_POSITION;
                float3 normalWS   : TEXCOORD0;
                float3 viewDirWS  : TEXCOORD1;
                float4 color      : COLOR;
                float2 uv         : TEXCOORD2;
                float3 worldPos   : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float3 posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldPos = posWS;
                o.normalWS = UnityObjectToWorldNormal(v.normal);
                o.viewDirWS = normalize(_WorldSpaceCameraPos - posWS);
                o.color = v.color;
                o.uv = v.uv;
                TRANSFER_SHADOW(o);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float3 normal = normalize(i.normalWS);
                float3 view = normalize(i.viewDirWS);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                if (dot(lightDir, lightDir) < 0.1) lightDir = normalize(float3(0.35, 0.85, -0.40));

                float3 lightCol = _LightColor0.rgb;
                if (dot(lightCol, lightCol) < 0.1) lightCol = float3(1.0, 0.98, 0.92);

                UNITY_LIGHT_ATTENUATION(shadow_atten, i, i.worldPos);

                float NdotL = saturate(dot(normal, lightDir));
                float toon = smoothstep(0.35, 0.55, NdotL) * 0.35 + 0.65;

                // Glossy plastic / enamel sun gleam
                float3 halfVector = normalize(lightDir + view);
                float NdotH = saturate(dot(normal, halfVector));
                float spec = (pow(NdotH, 18.0) * 0.70 + smoothstep(0.92, 0.98, NdotH) * 0.60) * shadow_atten;

                // Soft rim light
                float rim = 1.0 - saturate(dot(view, normal));
                float rimVal = pow(rim, _RimPower) * _RimColor.a;

                float4 texCol = tex2D(_MainTex, i.uv);
                float3 vCol = any(i.color.rgb) ? i.color.rgb : float3(1.0, 1.0, 1.0);
                float3 baseCol = _Color.rgb * texCol.rgb * vCol;
                float3 ambSky = unity_AmbientSky.rgb;
                if (dot(ambSky, ambSky) < 0.1) ambSky = float3(0.40, 0.50, 0.40);

                float3 litCol = baseCol * (lightCol * (toon * shadow_atten) + ambSky * 0.40);
                litCol += _RimColor.rgb * rimVal;
                litCol += lightCol * spec;

                return half4(litCol, _Color.a * texCol.a * (any(i.color.rgb) ? i.color.a : 1.0));
            }
            ENDCG
        }
    }

    Fallback "Mobile/Diffuse"
}
