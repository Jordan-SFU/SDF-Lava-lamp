Shader "Unlit/SimpleShader" {
    Properties {
        // _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Float) = 32
        _Fresnel ("Fresnel", Float) = 1
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // Mesh data: vertex position, normal, uv, etc.
            struct VertexInput {
                float4 vertex : POSITION;
                float4 colors : COLOR;
                float3 normal : NORMAL;
            };

            // interpolators -> data passed from vertex shader to fragment shader
            struct VertexOutput {
                float4 clipSpacePos : SV_POSITION;
                float3 normal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            // sampler2D _MainTex;
            // float4 _MainTex_ST;

            float4 _Color;
            float _Gloss;
            float _Fresnel;

            // Vertex shader -> Returns vertex position in clip space
            VertexOutput vert (VertexInput i) {
                VertexOutput o;

                o.clipSpacePos = UnityObjectToClipPos(i.vertex);
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.normal = i.normal;

                return o;
            }

            // Fragment shader -> Returns color of the pixel
            fixed4 frag (VertexOutput o) : SV_Target {
                // o.normal is interpolated -> need to normalize
                float3 normal = normalize(o.normal);

                // Lighting

                // Direct diffuse light
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightFalloff = max(dot(normal, lightDir), 0); // can also use saturate
                float3 lightColor = _LightColor0.rgb;
                float3 directDiffuseLight = lightFalloff * lightColor;

                // Ambient light
                float3 ambientLight = float3(0.1, 0.1, 0.1);

                // Direct specular light
                float3 camPos = _WorldSpaceCameraPos;
                float3 viewDir = normalize(camPos - o.worldPos);
                float3 reflectDir = reflect(-viewDir, normal);
                float3 specularFalloff = pow(max(dot(lightDir, reflectDir), 0), _Gloss) * lightColor;
                float3 specularColor = lightColor;
                float3 specular = specularFalloff * specularColor;

                // Fresnel
                float fresnel = pow(1 - max(dot(viewDir, normal), 0), _Fresnel);

                // Composite light
                float3 diffuseLight = directDiffuseLight + ambientLight;
                float3 finalSurfaceColor = diffuseLight * _Color.rgb; // Apply color of the object

                return float4(finalSurfaceColor + specular + fresnel, 1);
            }

            ENDCG
        }
    }
}
