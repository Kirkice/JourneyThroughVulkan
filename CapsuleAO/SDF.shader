Shader "Hidden/sdf_shadow"
{
    Properties
    {
        _MainTex("MainTex",2D) = "White"{}
    }

    SubShader
    {

        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
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
                float2 TexC : TEXCOORD0;
            };

            struct VertexOut
            {
                float4 PosH : SV_POSITION;
                float3 PosW : TEXCOORD0;
                float4 ScreenUV : TEXCOORD1;
                float2 TexC : TEXCOORD2;
            };

            uniform TEXTURE2D(_MainTex);
            uniform SAMPLER(sampler_MainTex);

            uniform TEXTURE3D(_Body3D);
            uniform SAMPLER(sampler_Body3D);

            uniform float4 _FrustumCorners[4];

            uniform float4 _CubePos;
            uniform float4 _CubeScale;
            // uniform TEXTURE3D(_Face3D);
            // uniform SAMPLER(sampler_Face3D);
            //
            // uniform TEXTURE3D(_Hair3D);
            // uniform SAMPLER(sampler_Hair3D);
            //
            // uniform TEXTURE3D(_Weapon3D);
            // uniform SAMPLER(sampler_Weapon3D);

            // float4x4 _inverse_transform_array[4];
            // float4 _half_extents_array[4];
            // float4 _os_center_array[4];
            // float4 _ws_center_array[4];
            // float4 _ws_axis_array[12];
            // float _sdf_idx_array[4];

            VertexOut VS(VertexIn vin)
            {
                VertexOut vout;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(vin.PosL);
                vout.PosH = vertexInput.positionCS;
                vout.PosW = _FrustumCorners[vin.TexC.x + vin.TexC.y * 2];
                vout.TexC = vin.TexC;
                vout.ScreenUV = ComputeScreenPos(vout.PosH);
                return vout;
            }

            //------------------------------------------------------------------

            float sdPlane(float3 p)
            {
                return p.y;
            }

            float sdBox(float3 p, float3 b)
            {
                float3 d = abs(p) - b;
                return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
            }

            //------------------------------------------------------------------

            float sample_sdf(in float3 pos)
            {
                float3 remapped_p = pos - (_CubePos.xyz - float3(0.5,0.5,0.5) * _CubeScale.xyz);
                float3 box_size   = _CubeScale.xyz;

                float3 uvw = (remapped_p / box_size);
                half sdf_tex = SAMPLE_TEXTURE3D_LOD(_Body3D,sampler_Body3D, uvw, 0.0f).r;
                return sdf_tex;
            }
            
            float map(in float3 pos)
            {
                float sdf = sample_sdf(pos);
                float out_map = min(sdPlane(pos.xyz - float3(0.0, 0.0, 0.0)),sdf);
                           //sdBox(pos.xyz - _CubePos.xyz, float3(0.5,0.5,0.5) * _CubeScale.xyz));
                return out_map;
            }

            //------------------------------------------------------------------

            float calcSoftshadow(in float3 ro, in float3 rd, in float mint, in float tmax)
            {
                float res = 1.0;
                float t = mint;
                float ph = 1e10; // big, such that y = 0 on the first iteration

                for (int i = 0; i < 64; i++)
                {
                    float h = map(ro + rd * t);
    
                    // use this if you are getting artifact on the first iteration, or unroll the
                    // first iteration out of the loop
                    //float y = (i==0) ? 0.0 : h*h/(2.0*ph); 

                    float y = h * h / (2.0 * ph);
                    float d = sqrt(h * h - y * y);
                    res = min(res, 50.0 * d / max(0.0, t - y));
                    ph = h;
                    t += h;
                    if (res < 0.0001 || t > tmax)
                        break;
                }
                res = clamp(res, 0.0, 1.0);
                return res * res * (3.0 - 2.0 * res);
            }

            float3 calcNormal(in float3 pos)
            {
                float2 e = float2(1.0, -1.0) * 0.5773 * 0.0005;
                return normalize(e.xyy * map(pos + e.xyy) +
                    e.yyx * map(pos + e.yyx) +
                    e.yxy * map(pos + e.yxy) +
                    e.xxx * map(pos + e.xxx));
            }

            float castRay(in float3 ro, in float3 rd)
            {
                float tmin = 1.0;
                float tmax = 20.0;

                float t = tmin;
                for (int i = 0; i < 64; i++)
                {
                    float precis = 0.0005 * t;
                    float res = map(ro + rd * t);
                    
                    if (res < precis || t > tmax)
                        break;
                    
                    t += res;
                }

                if (t > tmax) t = -1.0;
                return t;
            }

            float calcAO(in float3 pos, in float3 nor)
            {
                float occ = 0.0;
                float sca = 1.0;
                for (int i = 0; i < 5; i++)
                {
                    float h = 0.001 + 0.15 * float(i) / 4.0;
                    float d = map(pos + h * nor);
                    occ += (h - d) * sca;
                    sca *= 0.95;
                }
                return clamp(1.0 - 1.5 * occ, 0.0, 1.0);
            }

            float3 render(in float3 ro, in float3 rd, in float3 L)
            {
                float3 col = float3(1, 1, 1);
                float t = castRay(ro, rd);

                if (t > -0.5)
                {
                    float3 pos = ro + t * rd;
                    float3 nor = calcNormal(pos);

                    // shadow
                    float3 lig = normalize(L);
                    float shadow = calcSoftshadow(pos, lig, 0.02, 20.0);
                    col = min(shadow,col);
                    
                    // ambient occlusion
                    // float occ = calcAO(pos, nor);
                    // col = min(occ,col);
                }
                return col;
            }

            half4 PS(VertexOut pin) : SV_Target
            {
                float2 screenUV = pin.ScreenUV.xy / pin.ScreenUV.w;
                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, screenUV);

                // Instance instance[4];
                //
                // UNITY_UNROLL
                // for (int i = 0; i < 4; i++)
                // {
                //     instance[i].inverse_transform = _inverse_transform_array[i];
                //     instance[i].half_extents = _half_extents_array[i];
                //     instance[i].os_center = _os_center_array[i];
                //     instance[i].ws_center = _ws_center_array[i];
                //     for (int j = 0; j < 3; j++)
                //         instance[i].ws_axis[j] = _ws_axis_array[i * 3 + j];
                //
                //     instance[i].sdf_idx = _sdf_idx_array[i];
                // }

                Light mainLight = GetMainLight();

                // ray direction
                float3 rd = normalize(pin.PosW - GetCameraPositionWS());
                float3 ro = GetCameraPositionWS();

                // render	
                float3 col = render(ro, rd, mainLight.direction);

                return float4(col, 1);
            }
            ENDHLSL
        }
    }
}