Shader "Unlit/water_3_test"
{
  SubShader {
        Tags { "Queue"="Transparent" "RenderType"="Opaque" }
 
        //抓取屏幕图像并存储在名为_GrabTex的纹理中
        GrabPass { "_GrabTex" }
 
        pass {
            CGPROGRAM
 
        #pragma vertex vert
        #pragma fragment frag
 
        #include "UnityCG.cginc"
 
        sampler2D _GrabTex;
        float4 _GrabTex_ST;
 
        struct a2v {
            float4 vertex : POSITION;
            float4 texcoord : TEXCOORD0;
        };
 
        struct v2f {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
        };
 
        v2f vert(a2v v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.texcoord, _GrabTex);
            return o;
        }
 
        fixed4 frag(v2f i) : SV_Target {
            fixed3 color = tex2D(_GrabTex, i.uv).rgb;
            return fixed4(color, 1.0);
        }
 
        ENDCG
        }
 
        
    }
 
    FallBack "Diffuse"

}
