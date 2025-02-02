Shader "Unlit/SDF" {
    Properties {
        _Color1 ("Color 1", Color) = (1, 1, 1, 1)
        _Color2 ("Color 2", Color) = (1, 1, 1, 1)
        _Fresnel ("Fresnel", Float) = 1
        _Position ("Position", Vector) = (0, 0, 0, 0)
        _GlassColor ("Glass Color", Color) = (1, 1, 1, 1)
        _IOR ("IOR", Range(1, 2)) = 1.1
        _RefractionStrength ("Refraction Strength", Range(0, 2)) = 0.5
        _Transparency ("Transparency", Range(0, 1)) = 0.5
        _ShapeType ("Shape Type", Int) = 0
    }

    SubShader {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        Pass {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // Mesh data: vertex position, normal, uv, etc.
            struct VertexInput {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            // interpolators -> data passed from vertex shader to fragment shader
            struct VertexOutput {
                float4 clipSpacePos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            // Vertex shader -> Returns vertex position in clip space
            VertexOutput vert (VertexInput i) {
                VertexOutput o;

                o.clipSpacePos = UnityObjectToClipPos(i.vertex);
                o.worldPos = mul(unity_ObjectToWorld, i.vertex).xyz;
                o.normal = i.normal;

                return o;
            }

            struct Sphere {
                float3 center;
                float radius;
            };

            int _ShapeType;

            float3 _Position;
            Sphere spheres[8];

            void initSpheres() {
                float slowTime = _Time.y * 0.3; // Slower overall movement
                float verySlowTime = _Time.y * 0.5; // Even slower for horizontal drift
                float fastTime = _Time.y * .75; // Faster time scale for quick-moving spheres
                
                // Bottom sphere
                spheres[0].center = float3(
                    sin(verySlowTime) * 0.2,
                    -sin(slowTime) * 1 - 0.5,
                    0
                ) + _Position;
                spheres[0].radius = 0.3;
            
                // Large middle sphere
                spheres[1].center = float3(
                    cos(verySlowTime + 1.5) * 0.4,
                    sin(slowTime * 1.1 + 2.1) * 0.6,
                    0
                ) + _Position;
                spheres[1].radius = 0.4;
            
                // Small trailing sphere
                spheres[2].center = float3(
                    sin(verySlowTime + 3.14) * 0.25,
                    -cos(slowTime * 1 + 1.2) * 0.7 + 0.2,
                    0
                ) + _Position;
                spheres[2].radius = 0.2;
            
                // Medium rising sphere
                spheres[3].center = float3(
                    cos(verySlowTime + 4.7) * 0.2,
                    -sin(slowTime * 0.9 - 1.5) * 0.65,
                    0
                ) + _Position;
                spheres[3].radius = 0.25;
            
                // Small top sphere
                spheres[4].center = float3(
                    sin(verySlowTime - 2.1) * 0.55,
                    cos(slowTime * 0.85 + 3.9) * 0.75 + 0.3,
                    0
                ) + _Position;
                spheres[4].radius = 0.2;

                // New large bottom hovering sphere
                spheres[5].center = float3(
                    cos(verySlowTime * 0.7) * 0.5,
                    -1.2 + sin(slowTime * 0.5) * 0.2, // Hovers near bottom
                    0
                ) + _Position;
                spheres[5].radius = 0.45;
                
                // Small fast-moving spheres
                spheres[6].center = float3(
                    sin(fastTime * 1.2) * 0.4,
                    cos(fastTime) * 0.3,
                    0
                ) + _Position;
                spheres[6].radius = 0.15;
                
                spheres[7].center = float3(
                    cos(fastTime * 0.8 + 1.5) * 0.35,
                    sin(fastTime * 1.1) * 0.4,
                    0
                ) + _Position;
                spheres[7].radius = 0.12;
                

                for (int i = 0; i < 8; i++) {
                    spheres[i].radius *= 1.25;
                    spheres[i].center.y -= .5;
                    spheres[i].center.y *= 1.5;
                }
            }


            float smoothMin(float a, float b, float k) {
                // Add bounds checking to k to prevent division by zero
                k = max(k, 0.0001);
                float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
                return lerp(b, a, h) - k * h * (1.0 - h);
            }

            // Signed Distance Function (SDF) -> Sphere
            float SDF_Sphere(float3 p, float radius, float3 center){
                return length(p - center) - radius;
            }

            // Signed Distance Function (SDF) -> Box
            float SDF_Box(float3 p, float size, float3 center) {
                float3 q = abs(p - center) - size + 0.1;
                return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - 0.1;
            }

            float3x3 rotateX(float angle) {
                float s = sin(angle);
                float c = cos(angle);
                return float3x3(
                    1, 0, 0,
                    0, c, -s,
                    0, s, c
                );
            }

            float3x3 rotateY(float angle) {
                float s = sin(angle);
                float c = cos(angle);
                return float3x3(
                    c, 0, s,
                    0, 1, 0,
                    -s, 0, c
                );
            }

            float3x3 rotateZ(float angle) {
                float s = sin(angle);
                float c = cos(angle);
                return float3x3(
                    c, -s, 0,
                    s, c, 0,
                    0, 0, 1
                );
            }

            // Modify SDF_Blobs function
            float SDF_Blobs(float3 p){
                initSpheres();
                float d;
                
                // Create unique rotation for first shape
                float3x3 rot0 = mul(mul(
                    rotateX(sin(_Time.y * 0.5) * 0.2),
                    rotateY(cos(_Time.y * 0.4) * 0.2)),
                    rotateZ(sin(_Time.y * 0.3) * 0.2)
                );
                
                // Initialize with first shape
                float3 rotatedP = mul(rot0, p - spheres[0].center) + spheres[0].center;
                if (_ShapeType == 0) {
                    d = SDF_Sphere(rotatedP, spheres[0].radius, spheres[0].center);
                } else if (_ShapeType == 1) {
                    d = SDF_Box(rotatedP, spheres[0].radius, spheres[0].center);
                } 
                
                // Blend with remaining shapes
                for (int i = 1; i < 8; i++) {
                    // Create unique rotation per shape using different frequencies
                    float3x3 rot = mul(mul(
                        rotateX(sin(_Time.y * (0.3 + i * 0.1)) * 0.2),
                        rotateY(cos(_Time.y * (0.4 + i * 0.1)) * 0.2)),
                        rotateZ(sin(_Time.y * (0.5 + i * 0.1)) * 0.2)
                    );
                    
                    float3 rotatedP = mul(rot, p - spheres[i].center) + spheres[i].center;
                    float nextDist;
                    if (_ShapeType == 0) {
                        nextDist = SDF_Sphere(rotatedP, spheres[i].radius, spheres[i].center);
                    } else if (_ShapeType == 1) {
                        nextDist = SDF_Box(rotatedP, spheres[i].radius, spheres[i].center);
                    }
                    d = smoothMin(d, nextDist, 0.35);
                }
                
                return clamp(d, -10.0, 10.0);
            }

            float4 _Color1;
            float4 _Color2;

            float _Fresnel;

            float _GlassColor;
            float _IOR;
            float _RefractionStrength;

            float _Transparency;

            // Fragment shader -> Returns color of the pixel
            fixed4 frag (VertexOutput o) : SV_Target {
                float3 meshNormal = normalize(o.normal);

                // Initialization
                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDirection = normalize(o.worldPos - rayOrigin);
                float3 posAlongRay = rayOrigin;

                // Refraction
                float3 refractedRay = refract(rayDirection, meshNormal, 1 / _IOR);
                rayDirection = lerp(refractedRay, rayDirection, _RefractionStrength);

                float t = 0;
                float3 color = float3(0, 0, 0);
                float alpha = 0;

                // Raymarching
                for (int i = 0; i < 50; i++) {
                    posAlongRay = rayOrigin + t * rayDirection;
                    float dist = SDF_Blobs(posAlongRay);

                    if (dist < 0.001) {
                        color = float3(1, 1, 1);
                        alpha = 1.0;
                        break;
                    }

                    t += dist;
                }

                // Calculate normal
                float epsilon = 0.01;
                float centerDist = SDF_Blobs(posAlongRay);
                float xDist = SDF_Blobs(posAlongRay + float3(epsilon, 0, 0));
                float yDist = SDF_Blobs(posAlongRay + float3(0, epsilon, 0));
                float zDist = SDF_Blobs(posAlongRay + float3(0, 0, epsilon));
                float3 normal = normalize((float3(xDist, yDist, zDist) - centerDist));

                // SDF Fresnel
                float3 viewDir = normalize(rayOrigin - posAlongRay);
                float fresnel = pow(1 - max(dot(viewDir, normal), 0), max(_Fresnel, 0));

                // Improved Glass Fresnel
                float glassFresnelPower = 3; // Lower power for smoother falloff
                float baseFresnel = 0.2; // Minimum glass visibility
                float glassFresnel = baseFresnel + (1-baseFresnel) * 
                                     pow(1 - max(dot(viewDir, meshNormal), 0), glassFresnelPower);

                // Stylized Glass Effects
                float3 rimColor = float3(0.8, 0.9, 1.0); // Slight blue tint for rim
                float rimIntensity = 2;
                float rim = pow(1 - max(dot(viewDir, meshNormal), 0), 2) * rimIntensity;


                float3 glassColor = _GlassColor;
                float3 glassFinalColor = (glassColor + rimColor * rim) * _Transparency;

                // Specular
                float3 lightDir = normalize(float3(1, 1, 1));
                float3 reflectDir = reflect(-lightDir, normal);
                float3 specular = pow(max(dot(viewDir, reflectDir), 0), 1024) * 20 * float3(1, 1, 1);

                float3 blobFinalColor = color * lerp(_Color1.rgb, _Color2.rgb, fresnel) + specular;

                // Blend final colors - modify alpha for better glass visibility
                alpha = max(alpha, glassFresnel * _Transparency);
                return float4(lerp(blobFinalColor, glassFinalColor, _Transparency), alpha);
            }

            ENDCG
        }
    }
}
