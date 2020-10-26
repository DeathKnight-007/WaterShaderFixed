Shader "water_3" {
    Properties {
        _Color ("Main Color", Color) = (0, 0.15, 0.115, 1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _WaveMap ("Wave Map", 2D) = "bump" {}
        _Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
        _WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01
        _WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01
        _Distortion ("Distortion", Range(0, 100)) = 10   //模拟折射图像扭曲程度

        [HideInInspector]_DropPos_1("Drop Position 1", Vector) = (0, 0, 0, 0)
        [HideInInspector]_DropPos_2("Drop Position 2", Vector) = (0, 0, 0, 0)
        [HideInInspector]_DropPos_3("Drop Position 3", Vector) = (0, 0, 0, 0)
        [HideInInspector]_NowTime_1("NowTime 1", float) = 0
        [HideInInspector]_NowTime_2("NowTime 2", float) = 0
        [HideInInspector]_NowTime_3("NowTime 3", float) = 0
        [HideInInspector]_SplashScale_1("SplashScale 1", float) = 1
        [HideInInspector]_SplashScale_2("SplashScale 2", float) = 1
        [HideInInspector]_SplashScale_3("SplashScale 3", float) = 1

        [KeywordEnum(START, STOP)]_WATER_SPLASH("water splash", float) = 1
    }
    SubShader {
        // We must be transparent, so other objects are drawn before this one.
        Tags { "Queue"="Transparent" "RenderType"="Opaque" }
        
        // This pass grabs the screen behind the object into a texture.
        // We can access the result in the next pass as _RefractionTex
        GrabPass { "_RefractionTex" }
        
        Pass {
            Tags { "LightMode"="ForwardBase" }
            
            CGPROGRAM
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            
            #pragma multi_compile_fwdbase
            #pragma multi_compile _WATER_SPLASH_START _WATER_SPLASH_STOP
            #define PI 3.141592653
            
            #pragma vertex vert
            #pragma fragment frag
            
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _WaveMap;
            float4 _WaveMap_ST;
            samplerCUBE _Cubemap;
            fixed _WaveXSpeed;
            fixed _WaveYSpeed;
            float _Distortion;  
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;

            float4  _DropPos_1;
            float _NowTime_1;
            float4  _DropPos_2;
            float _NowTime_2;
            float4  _DropPos_3;
            float _NowTime_3;
            float _SplashScale_1;
            float _SplashScale_2;
            float _SplashScale_3;
            
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; 
                float4 texcoord : TEXCOORD0;
            };
            
            struct v2f {
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float4 TtoW0 : TEXCOORD2;  
                float4 TtoW1 : TEXCOORD3;  
                float4 TtoW2 : TEXCOORD4; 
            };


            float3 GetNewNormal(float3 fpos, float3 droppos, float nowtime, float scale){
             float dis = length(fpos - droppos);
            if(dis > scale)
               dis = 0;
            float dropFrac = 1 - (_Time.y - nowtime);
            float final = dropFrac * sin(clamp((dropFrac - 1.0 + dis/scale) * 9, 0.0, 4.0) * PI);
            return  float3(dis/scale * final, dis/scale * final , 1);
            }
            
            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.scrPos = ComputeGrabScreenPos(o.pos);
                
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
                
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
                
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target {
                //世界坐标
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                //视角
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                //水流流动速度
                float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);
                
                // Get the normal in tangent space
                fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb;
                fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;
                fixed3 bump = normalize(bump1 + bump2);
                
                // Compute the offset in tangent space
                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
                fixed3 refrCol = tex2D( _RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;

                float3 mnormal_1 = float3 (0, 0, 0);
                float3 mnormal_2 = float3 (0, 0, 0);
                float3 mnormal_3 = float3 (0, 0, 0);

                 #ifdef _WATER_SPLASH_START
                       mnormal_1 = GetNewNormal(worldPos, _DropPos_1.xyz, _NowTime_1, _SplashScale_1);
                       mnormal_2 = GetNewNormal(worldPos, _DropPos_2.xyz, _NowTime_2, _SplashScale_2);
                       mnormal_3 = GetNewNormal(worldPos, _DropPos_3.xyz, _NowTime_3, _SplashScale_3);
                #endif
                bump += mnormal_1 + mnormal_2 + mnormal_3;
                
                // Convert the normal to world space
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
               
                //
                fixed4 texColor = tex2D(_MainTex, i.uv.xy + speed);
                fixed3 reflDir = reflect(-viewDir, bump);
                fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb * _Color.rgb;
                
                //菲涅尔
                fixed fresnel =  pow(1 - saturate(dot(viewDir, bump)), 0.6);
                fixed3 finalColor = reflCol * fresnel + refrCol * (1 - fresnel);
                
                return fixed4(finalColor.xyz,1);
            }
            
            ENDCG
        }
    }
    // Do not cast shadow
    FallBack Off
}