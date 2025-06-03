Shader "Custom/RetroQuantizedLit"
{
    Properties
    {
        _Color ("Color Base", Color) = (1,1,1,1)
        _MainTex ("Textura", 2D) = "white" {}
        _Levels ("Niveles de Luz", Range(1,8)) = 4
        _MySpecColor ("Color Especular", Color) = (1,1,1,1)
        _SpecPower ("Potencia Especular", Range(1,64)) = 16
        _EnableSpec ("Habilitar Especular", Float) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
        fixed4 _Color;
        int _Levels;
        fixed4 _MySpecColor;
        float _SpecPower;
        float _EnableSpec;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
            float3 normal = normalize(o.Normal);
            float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

            // Luz difusa tradicional (Lambert)
            float NdotL = saturate(dot(normal, lightDir));

            // Cuantización de la luz difusa
            float stepped = floor(NdotL * _Levels) / (_Levels - 1.0);

            // Color base con luz cuantizada
            fixed3 diffuse = stepped * _Color.rgb * tex.rgb;

            // Cálculo del specular cuantizado (estilo arcade)
            float3 view = normalize(IN.viewDir);
            float3 halfDir = normalize(lightDir + view);
            float spec = pow(saturate(dot(normal, halfDir)), _SpecPower);
            spec = floor(spec * _Levels) / (_Levels - 1.0);

            if (_EnableSpec < 0.5)
                spec = 0;

            // Asignación de salidas
            o.Albedo = diffuse;
            o.Metallic = 0;
            o.Smoothness = 0.0;
            o.Emission = _MySpecColor.rgb * spec;
            o.Alpha = 1;
        }
        ENDCG
    }

    FallBack "Diffuse"
}