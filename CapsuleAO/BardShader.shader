Shader "testsdf"
{
    Properties
    {
        _MainColor("MainColor",Color) = (1,1,1,1)
        _Color("Color",Color) = (1,1,1,1)
        [Toggle]_UseSDFShadow("Use SDF",float) = 0
    }

    SubShader
    {

//        Tags{"Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        ENDHLSL

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
//            Blend SrcAlpha  OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma vertex VS
            #pragma fragment PS

            struct VertexIn
            {
                float4 PosL : POSITION;
            };

            struct VertexOut
            {
                float4 PosH : SV_POSITION;
                float4 shadowCoord : TEXCOORD0;
                float3 PosW : TEXCOORD1;
                float4 ScreenUV : TEXCOORD2;
            };

            TEXTURE2D(_SDFShadowTex);
            SAMPLER(sampler_SDFShadowTex);
            
            CBUFFER_START(UnityPerMaterial)
            uniform half4 _Color;
            uniform half4 _MainColor;
            uniform float _UseSDFShadow;
            CBUFFER_END

            VertexOut VS(VertexIn vin)
            {
                VertexOut vout;
                vout.PosH = TransformObjectToHClip(vin.PosL);
                vout.PosW = TransformObjectToWorld(vin.PosL);
                vout.shadowCoord = TransformWorldToShadowCoord(vout.PosW);
                vout.ScreenUV = ComputeScreenPos(vout.PosH);
                return vout;
            }

            half4 PS(VertexOut pin) : SV_Target
            {
                float4 SHADOW_COORDS = TransformWorldToShadowCoord(pin.PosW);
                half shadow = 1 - saturate(MainLightRealtimeShadow(SHADOW_COORDS));

                return shadow.xxxx;
                UNITY_BRANCH
                if (_UseSDFShadow > 0.5)
                {
                    shadow = SAMPLE_TEXTURE2D(_SDFShadowTex,sampler_SDFShadowTex, pin.ScreenUV.xy / pin.ScreenUV.w);
                    shadow = 1 - saturate(pow(shadow,1.2) * 10);
                }
                
                return lerp(_MainColor, _Color, shadow);
            }
            ENDHLSL
        }
    }
}