// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Water_1"{
	Properties
	{
		_MainTex("Main Texture", 2D) = ""{}
		[Toggle(_Water_Splash)]_Water_Splash("Water Splash", float) = 0

		[Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor", float) = 0 
		[Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor", float) = 0 

		[Enum(UnityEngine.Rendering.BlendOp)]_BlendOp("Blend Operation", float) = 0 

		[KeywordEnum(LAMBERT, HALFLAMBERT)]_Diffuse_LightModel("Diffuse Light Model", float) = 0
		[KeywordEnum(PHONG, BLINN)]_Specular_LightModel("Specular Light Model", float) = 0

		_Gloss("gloss", Range(0, 50)) = 0

	}
	Subshader
	{
        Tags{"Queue" = "Transparent" "IgnoreProjector" = "True" "DisableBatching" = "True" "RenderType" = "Transparent"}
        Cull Back 
        ZWrite On 
        ColorMask RGBA 

        Pass{
            Tags{"LightMode" = "ForwardBase"}
            Blend [_SrcFactor] [_DstFactor]
            BlendOp [_BlendOp]


            CGPROGRAM
            #pragma multi_compile _WATER_SPLASH_ON
            #pragma multi_compile _DIFFUSE_LIGHTMODEL_LAMBERT _DIFFUSE_LIGHTMODEL_HALFLAMBERT
            #pragma multi_compile _SPECULAR_LIGHTMODEL_PHONG  _SPECULAR_LIGHTMODEL_BLINN
            #pragma multi_compile_fwdbase
            #pragma vertex  vert 
            #pragma fragment frag 
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4  _MainTex_ST;
            float _Gloss;

            struct a2f {
            	float4 vertex : POSITION;
            	float3 normal : NORMAL;
            	float4 tangent : TANGENT;
            	float4 texcoord : TEXCOORD0; 
            };
            struct v2f{
            	float4 pjposition : SV_POSITION;
            	float4 wdposition : TEXCOORD0;
            	float3 wdnormal : NORMAL;
            	float2 uv : TEXCOORD1;  
            };   

            v2f vert(a2f v){
            	v2f o;            	
            	     	
                float dist = distance(v.vertex.xyz, float3(0,0,0));   
                float height = sin(dist * 2 + _Time.z); 
                v.vertex += height;
                o.pjposition = UnityObjectToClipPos(v.vertex);       
            	o.wdposition = mul(unity_ObjectToWorld, v.vertex);
            	o.wdnormal = normalize(mul(transpose((float3x3)unity_WorldToObject), v.normal));
            	o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
            	return  o;
            }
            fixed4 frag(v2f i) : SV_TARGET{
                fixed4 col = tex2D(_MainTex, i.uv);
                //#ifdef _WATER_SPLASH_ON
                   //return col;
                //#endif               
                   fixed4 ambientColor = UNITY_LIGHTMODEL_AMBIENT;
                   fixed4 diffuseColor;
                   fixed4 specularColor;
                   float atten;
                   fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);                
                   //漫反射
                   #if defined(_DIFFUSE_LIGHTMODEL_LAMBERT)
                        diffuseColor = _LightColor0 * col * saturate(dot(i.wdnormal, lightDir));
                   #elif defined(_DIFFUSE_LIGHTMODEL_HALFLAMBERT)
                        diffuseColor = _LightColor0 * col * (dot(i.wdnormal, lightDir) / 2 + 0.5);
                   #endif
                   //高光反射
                   #if defined(_SPECULAR_LIGHTMODEL_PHONG)
                        fixed3 v = normalize(_WorldSpaceCameraPos.xyz - i.wdposition.xyz);
                        fixed3 r = normalize(reflect(-lightDir, i.wdnormal)); 
                        specularColor = _LightColor0 * col * pow(saturate(dot(v, r)), _Gloss);
                   #elif defined(_SPECULAR_LIGHTMODEL_BLINN)
                        fixed3 v = normalize(_WorldSpaceCameraPos.xyz - i.wdposition.xyz);
                        fixed3 halfvl = normalize(v + normalize(lightDir));
                        specularColor = _LightColor0 * col * pow(dot(v, halfvl),_Gloss);
                   #endif
                   return diffuseColor + specularColor + ambientColor;               
            }
            ENDCG
        }
	}
}