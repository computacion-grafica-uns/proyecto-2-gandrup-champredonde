Shader "Practica/Blinn-Phong-Multitextura"
{
    Properties
    {
        // Material
        _MaterialKa ("Materialka", Vector) = (0, 0, 0, 0) 
        _MaterialKs ("Materialks", Vector) = (0, 0, 0, 0)  
        _Material_n  ("Material_n", Float) = 0.5

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

        //Texturas
        [NoScaleOffset] _Text1 ("Texture1", 2D) = "white" {}
        [NoScaleOffset] _Text2 ("Texture2", 2D) = "white" {}
        _IntencidadText1  ("Textura1 Intencidad", Range(0.0,1)) = 0.5
        _IntencidadText2  ("Textura2 Intencidad", Range(0.0,1)) = 0.5

    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD2;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 position_w : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            // Material
            float4 _MaterialKa;
            float4 _MaterialKd;
            float4 _MaterialKs;
            float _Material_n;
            
            //Camara
            float4 _CameraPosition_w;

            //Texturas
            sampler2D _Text1;
            sampler2D _Text2;
            float _IntencidadText1;
            float _IntencidadText2;

            // Luz ambiental
            float4 _AmbientLight;

            // Direccional
            float4 _DirLightDirection;
            float4 _DirLightColor;
            float _DirActiva;

            // Puntual
            float4 _PointLightPosition;
            float4 _PointLightColor;
            float _PointActiva;

            // Spot
            float4 _SpotLightPosition;
            float4 _SpotLightDirection;
            float4 _SpotLightColor;
            float _SpotLightApertura;
            float _SpotActiva;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.position_w = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal (v.normal);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f f) : SV_Target
            {
                float3 N = normalize(f.normal);
                float3 V = normalize(_CameraPosition_w.xyz - f.position_w);
                float3 col1 = 0;
                float3 col2 = 0;
                float3 col = 0;
                col1.rgb = tex2D(_Text1, f.uv); 
                col2.rgb = tex2D(_Text2, f.uv);
                col.rgb = col1.rgb*_IntencidadText1 + col2.rgb *_IntencidadText2 ;

                // Luz direccional
                float3 dirLight = 0;
                if(_DirActiva == 1)
                {
                    float3 L1 = normalize(-_DirLightDirection.xyz);
                    float NdotL1 = max(0, dot(N, L1));
                    float3 H1 = normalize(L1 + V);
                    float3 spec1 = pow(max(dot(N, H1), 0.0), _Material_n) * _MaterialKs.rgb;
                    float3 diff1 = NdotL1 * col.rgb;
                    dirLight = _DirLightColor.rgb * (diff1 + spec1) ;
                }
                //Luz puntual
                float3 pointLight = 0;
                if(_PointActiva == 1)
                {
                    float3 toPoint = _PointLightPosition.xyz - f.position_w;
                    float3 L2 = normalize(toPoint);
                    float dist = length(toPoint);
                    float atten = 1.0 / (1.0 + dist); // Atenuación simple
                    float NdotL2 = max(0, dot(N, L2));
                    float3 H2 = normalize(L2 + V);
                    float3 spec2 = pow(max(dot(N, H2), 0.0), _Material_n) * _MaterialKs.rgb;
                    float3 diff2 = NdotL2 * col.rgb;
                    pointLight = _PointLightColor.rgb * atten * (diff2 + spec2);
                }
                // Luz spot
                float3 spotLight = 0;
                if(_SpotActiva == 1)
                {
                    float3 L3 = normalize(_SpotLightPosition.xyz - f.position_w);
                    float3 spotDir = normalize(-_SpotLightDirection.xyz);
                    float angle = acos(dot(L3, spotDir));

                    if (angle < radians(_SpotLightApertura))
                    {
                        float NdotL3 = max(0, dot(N, L3));
                        float3 H3 = normalize(L3 + V);
                        float3 spec3 = pow(max(dot(N, H3), 0.0), _Material_n) * _MaterialKs.rgb;
                        float3 diff3 = NdotL3 * col.rgb;
                        spotLight = _SpotLightColor.rgb * (diff3+  spec3);
                    }
                }
                //Luz ambiental
                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;

                // resultado final
                fixed4 fragColor = 0;
                fragColor.rgb = ambient + dirLight + pointLight + spotLight;
                return fragColor;
            }
            ENDCG
        }
    }
}
