Shader "Custom/Cook-Torrance-Multitextura"
{
    Properties
    {
        // Material
        _MaterialKa ("Materialka", Vector) = (0.1, 0.1, 0.1, 0)
        _MaterialKd ("MaterialKd", Vector) = (1, 1, 1, 0) 
        _Fresnel ("Fresnel", Vector) = (1, 1, 1, 0)  
        _Roughness ("Roughness", Range(0.0, 1)) = 0.5

        // Cámara
        _CameraPosition_w ("Camera Position", Vector) = (0, 0, 0, 1)

        // Luz direccional
        _DirLightDirection ("Directional Light Direction", Vector) = (0, -1, 0, 0)
        _DirLightColor ("Directional Light Color", Color) = (1,1,1,1)
        _DirActiva ("Directional Light Activa",Float) = 1

        // Luz puntual
        _PointLightPosition ("Point Light Position", Vector) = (0, 2, 0, 1)
        _PointLightColor ("Point Light Color", Color) = (1, 0, 0, 1)
        _PointActiva ("Point Light Activa", Float) = 1
        
        // Luz spot
        _SpotLightPosition ("Spot Light Position", Vector) = (0, 3, 0, 1)
        _SpotLightDirection ("Spot Light Direction", Vector) = (0, -1, 0, 0)
        _SpotLightColor ("Spot Light Color", Color) = (0, 0, 1, 1)
        _SpotLightApertura ("Spot Light Apertura", Range(0.0, 90)) = 30
        _SpotActiva("Spot Light", Float) = 1

        // Luz ambiental
        _AmbientLight ("Ambient Light", Color) = (0.2, 0.2, 0.2, 1)

        // Texturas
        [NoScaleOffset] _TextC ("Texture cambio", 2D) = "white" {}
        [NoScaleOffset] _Text1 ("Texture1", 2D) = "white" {}
        [NoScaleOffset] _Text2 ("Texture2", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

        Pass
        {
            CGPROGRAM
            #pragma vertex vertexShader
            #pragma fragment fragmentShader
            #include "UnityCG.cginc"

            struct appdata {
                float4 position : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD2;
            };

            struct v2f {
                float4 position : SV_POSITION;
                float3 position_w : TEXCOORD0;
                float3 normal_w : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            // Material
            float4 _MaterialKa;
            float4 _MaterialKd;
            float4 _Fresnel;
            float _Roughness;

            // Textura
            sampler2D _Text1;
            sampler2D _Text2;
            sampler2D _TextC;

            // Camara
            float4 _CameraPosition_w;

            // Luces
            float4 _DirLightDirection, _DirLightColor;
            float4 _PointLightPosition, _PointLightColor;
            float4 _SpotLightPosition, _SpotLightDirection, _SpotLightColor;
            float _SpotLightApertura;
            float _DirActiva, _PointActiva, _SpotActiva;
            float4 _AmbientLight;

            v2f vertexShader(appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.position);
                o.position_w = mul(unity_ObjectToWorld, v.position).xyz;
                o.normal_w = UnityObjectToWorldNormal (v.normal);
                o.uv = v.uv;
                return o;
            }

            float DistributionGGX(float3 N, float3 H)
            {
                float r4 = pow(_Roughness,4.0);
                float NdotH = max(dot(N, H), 0.0);
                float denom = (NdotH * NdotH * (r4 - 1.0) + 1.0);
                return r4 / (UNITY_PI * denom * denom);
            }

            float GeometrySchlickGGX(float NdotX)
            {
                float k = pow(_Roughness + 1.0, 2.0) / 8.0;
                return NdotX / (NdotX * (1.0 - k) + k);
            }

            float GeometrySmith(float3 N, float3 V, float3 L)
            {
                return GeometrySchlickGGX(max(dot(N, V), 0.0)) *
                       GeometrySchlickGGX(max(dot(N, L), 0.0));
            }

            float3 FresnelSchlick(float cosTheta)
            {
                float3 F0 = _Fresnel;
                return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
            }

            float3 CookTorranceSpecular(float3 N, float3 V, float3 L, float3 lightColor)
            {
                float3 H = normalize(V + L);
                float NdotL = max(dot(N, L), 0.0);
                float NdotV = max(dot(N, V), 0.0);

                float3 F = FresnelSchlick(max(dot(H, V), 0.0));
                float D = DistributionGGX(N, H);
                float G = GeometrySmith(N, V, L);

                float3 specular = (D * G * F) / (4.0 * NdotV * NdotL + 0.001);
                return specular * lightColor * NdotL;
            }

            float3 BlinnPhongDiffuse(float3 N, float3 L, float3 lightColor, float3 text)
            {
                float NdotL = max(dot(N, L), 0.0); 
                return  text * lightColor * NdotL;
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal_w);
                float3 V = normalize(_CameraPosition_w.xyz - f.position_w);

                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;

                float3 text = 0;
                float3 unos = (1,1,1);
                text.rgb = tex2D(_Text1, f.uv).rgb * tex2D(_TextC, f.uv).rgb  + tex2D(_Text2, f.uv).rgb * (unos - tex2D(_TextC, f.uv).rgb);

                // Luz direccional
                float dirLight = 0;
                if(_DirActiva == 1)
                {
                    float3 L1 = normalize(-_DirLightDirection.xyz);
                    float3 diff1 = BlinnPhongDiffuse(N, L1, _DirLightColor.rgb,text.rgb);
                    float3 spec1 = CookTorranceSpecular(N, V, L1, _DirLightColor.rgb);
                    dirLight = diff1 + spec1;
                }
                // Luz puntual
                float3 pointLight = 0 ;
                if(_PointActiva == 1)
                {
                    float3 toPoint = _PointLightPosition.xyz - f.position_w;
                    float3 L2 = normalize(toPoint);
                    float dist = length(toPoint);
                    float atten = 1.0 / (1.0 + dist);
                    float3 diff2 = BlinnPhongDiffuse(N, L2, _PointLightColor.rgb * atten, text.rgb);
                    float3 spec2 = CookTorranceSpecular(N, V, L2, _PointLightColor.rgb * atten);
                    pointLight = diff2 + spec2;
                }
                // Luz spot
                float3 spotLight = 0;
                if(_SpotActiva == 1)
                {
                    float3 toSpot = _SpotLightPosition.xyz - f.position_w;
                    float3 L3 = normalize(toSpot);
                    float angle = degrees(acos(dot(L3, normalize(-_SpotLightDirection.xyz))));
                
                    if (angle < _SpotLightApertura)
                    {
                        float3 diff3 = BlinnPhongDiffuse(N, L3, _SpotLightColor.rgb,text.rgb);
                        float3 spec3 = CookTorranceSpecular(N, V, L3, _SpotLightColor.rgb);
                        spotLight = diff3 + spec3;
                    }
                }
                fixed4 fragColor = 0;
                fragColor.rgb = ambient + dirLight + pointLight + spotLight;
                return fragColor;
            }
            ENDCG
        }
    }
}
