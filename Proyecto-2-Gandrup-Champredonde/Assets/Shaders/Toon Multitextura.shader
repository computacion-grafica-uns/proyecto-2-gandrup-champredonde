Shader "Practica/Toon-Multitextura"
{
    Properties
    {
        // Material
        _MaterialKa ("Ambient", Color) = (0.1, 0.1, 0.1, 1)
        _MaterialKs ("Specular", Color) = (1, 1, 1, 1)
        _Roughness ("Roughness", Range(0.05, 1)) = 0.5

        // Textura
        [NoScaleOffset] _Tex1 ("Texture 1", 2D) = "white" {}
        [NoScaleOffset] _Tex2 ("Texture 2", 2D) = "black" {}

        // Cámara
        _CameraPosition_w ("Camera Position", Vector) = (0,0,0,1)

        // Luces
        _DirLightDirection ("Dir Light Dir", Vector) = (0, -1, 0, 0)
        _DirLightColor ("Dir Light Color", Color) = (1,1,1,1)
        _PointLightPosition ("Point Light Pos", Vector) = (0, 2, 0, 1)
        _PointLightColor ("Point Light Color", Color) = (1, 0, 0, 1)
        _SpotLightPosition ("Spot Light Pos", Vector) = (0, 3, 0, 1)
        _SpotLightDirection ("Spot Light Dir", Vector) = (0, -1, 0, 0)
        _SpotLightColor ("Spot Light Color", Color) = (0, 0, 1, 1)
        _SpotLightApertura ("Spot Apertura", Range(0,90)) = 30

        // Switches
        _DirActiva ("Activar Luz Direccional", Float) = 1
        _PointActiva ("Activar Luz Puntual", Float) = 1
        _SpotActiva ("Activar Luz Spot", Float) = 1

        _AmbientLight ("Ambient Light", Color) = (0.2, 0.2, 0.2, 1)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            // Propiedades materiales y escena
            float4 _MaterialKa, _MaterialKs;
            float _Roughness;
            float4 _CameraPosition_w;
            sampler2D _Tex1 , _Tex2;

            // Luz ambiental
            float4 _AmbientLight;

            // Luces
            float4 _DirLightDirection, _DirLightColor;
            float4 _PointLightPosition, _PointLightColor;
            float4 _SpotLightPosition, _SpotLightDirection, _SpotLightColor;
            float _SpotLightApertura;

            // Activadores
            float _DirActiva, _PointActiva, _SpotActiva;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                return o;
            }

            float ToonShade(float NdotL)
            {
                if (NdotL > 0.95) return NdotL;
                if (NdotL > 0.90) return 0.93;
                else if (NdotL > 0.75) return 0.85;
                else if (NdotL > 0.60) return 0.7;
                else if (NdotL > 0.40) return 0.55;
                else if (NdotL > 0.25) return 0.4;
                else if (NdotL > 0.10) return 0.2;
                else return 0.05;
            }

            fixed4 frag(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal);
                float3 V = normalize(_CameraPosition_w.xyz - f.worldPos);
                float3 texColor = tex2D(_Tex1, f.uv).rgb + tex2D(_Tex2, f.uv).rgb;
                float roughness = _Roughness;

                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;

                float3 color = ambient;

                // Direccional
                if (_DirActiva > 0.5)
                {
                    float3 L = normalize(-_DirLightDirection.xyz);
                    float NdotL = max(0, dot(N, L));
                    float toonDiff = ToonShade(NdotL);
                    float3 H = normalize(L + V);
                    float shininess = (1.0 - roughness) * 128.0;
                    float toonSpec = pow(ToonShade(dot(N, H)), shininess);
                    color += _DirLightColor.rgb * (toonDiff * texColor + toonSpec * _MaterialKs.rgb);
                }

                // Puntual
                if (_PointActiva > 0.5)
                {
                    float3 toL = _PointLightPosition.xyz - f.worldPos;
                    float3 L = normalize(toL);
                    float dist = length(toL);
                    float atten = 1.0 / (1.0 + dist);
                    float NdotL = max(0, dot(N, L));
                    float toonDiff = ToonShade(NdotL);
                    float3 H = normalize(L + V);
                    float shininess = (1.0 - roughness) * 128.0;
                    float toonSpec = pow(ToonShade(dot(N, H)), shininess);
                    color += _PointLightColor.rgb * atten * (toonDiff * texColor + toonSpec * _MaterialKs.rgb);
                }

                // Spot
                if (_SpotActiva > 0.5)
                {
                    float3 toL = _SpotLightPosition.xyz - f.worldPos;
                    float3 L = normalize(toL);
                    float angle = degrees(acos(dot(L, normalize(-_SpotLightDirection.xyz))));
                    if (angle < _SpotLightApertura)
                    {
                        float NdotL = max(0, dot(N, L));
                        float toonDiff = ToonShade(NdotL);
                        float3 H = normalize(L + V);
                        float shininess = (1.0 - roughness) * 128.0;
                        float toonSpec = pow(ToonShade(dot(N, H)), shininess);
                        color += _SpotLightColor.rgb * (toonDiff * texColor + toonSpec * _MaterialKs.rgb);
                    }
                }

                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
