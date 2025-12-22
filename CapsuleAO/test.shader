Shader "sdf_shadow"
{
    Properties
    {
        _MainTex("MainTex",3D) = "White"{}
        _ClipNum("Clip Num",Range(0,1)) = 0.0
    }

    SubShader
    {

        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        ENDHLSL

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex VS
            #pragma fragment PS

            struct VertexIn
            {
                float4 PosL : POSITION;
            };

            struct VertexOut
            {
                float4 PosH : SV_POSITION;
                float4 PosL : TEXCOORD0;
            };

            uniform TEXTURE3D(_MainTex);
            uniform SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
            uniform float _ClipNum;
            CBUFFER_END

            VertexOut VS(VertexIn vin)
            {
                VertexOut vout;
                vout.PosH = TransformObjectToHClip(vin.PosL);
                vout.PosL = vin.PosL;
                return vout;
            }

            half4 PS(VertexOut pin) : SV_Target
            {
                half sdf = SAMPLE_TEXTURE3D(_MainTex, sampler_MainTex, pin.PosL + half3(0.5,0.5,0.5)).r;
                return sdf.xxxx;
            }
            ENDHLSL
        }
    }
}