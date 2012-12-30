#version 110
#extension GL_ARB_texture_rectangle : enable

uniform vec2 dim;
uniform vec2 shift;
uniform vec2 scale;

uniform sampler2DRect depthTex;
uniform sampler2DRect normalTex;
uniform sampler2DRect distortTex;
uniform float distortionScale;

uniform vec2 principalPoint;
uniform vec2 fov;
uniform float xsimplify;
uniform float ysimplify;

uniform float farClip;
uniform float edgeClip;
uniform int useTexture;
uniform mat4 tTex;

uniform float frame;

varying vec3 normal;
varying vec3 distortionColorSample;

uniform float scanlineDiscardThreshold;
uniform float scanlineDiscardFrequency;

varying float scanlineDiscard;
varying float VZPositionValid0;

const float epsilon = 1e-6;

void main(void)
{
    //align to texture
    vec2 halfvec = vec2(.5,.5);
    float depth = texture2DRect(depthTex, floor(gl_Vertex.xy) + halfvec).r * 65535.;
    float right = texture2DRect(depthTex, floor(gl_Vertex.xy  + vec2(xsimplify,0.0)) + halfvec ).r * 65535.;
    float down  = texture2DRect(depthTex, floor(gl_Vertex.xy  + vec2(0.0,ysimplify)) + halfvec ).r * 65535.;
    float left  = texture2DRect(depthTex, floor(gl_Vertex.xy + vec2(-xsimplify,0.0)) + halfvec ).r * 65535.;
    float up    = texture2DRect(depthTex, floor(gl_Vertex.xy + vec2(0.0,-ysimplify)) + halfvec ).r * 65535.;
    float bl    = texture2DRect(depthTex, vec2(floor(gl_Vertex.x - xsimplify),floor( gl_Vertex.y + ysimplify)) + halfvec ).r * 65535.;
    float ur    = texture2DRect(depthTex, vec2(floor(gl_Vertex.x  + xsimplify),floor(gl_Vertex.y - ysimplify)) + halfvec ).r * 65535.;

    //TODO: make uniform var
    float nearClip = 20.0;
    //cull invalid verts
    VZPositionValid0 = (depth < farClip &&
                        right < farClip &&
                        down < farClip &&
                        left < farClip &&
                        up < farClip &&
                        bl < farClip &&
                        ur < farClip &&
                        
                        depth > nearClip &&
                        right > nearClip &&
                        down > nearClip &&
                        left > nearClip &&
                        up > nearClip &&
                        bl > nearClip &&
                        ur > nearClip &&
                        
                        abs(down - depth) < edgeClip &&
                        abs(right - depth) < edgeClip &&
                        abs(up - depth) < edgeClip &&
                        abs(left - depth) < edgeClip &&
                        abs(ur - depth) < edgeClip &&
                        abs(bl - depth) < edgeClip
                        ) ? 1.0 : 0.0;
    
	vec4 pos = vec4((gl_Vertex.x - principalPoint.x) * depth / fov.x,
                    (gl_Vertex.y - principalPoint.y) * depth / fov.y, depth, 1.0);

    vec3 surfaceNormal = texture2DRect(normalTex, floor(gl_Vertex.xy) + halfvec).xyz * 2.0 - 1.0;
    normal = normalize(gl_NormalMatrix * surfaceNormal);


    //projective texture on the geometry
    if(useTexture == 1){
        
        vec4 texCd = tTex * pos;
        texCd.xyz /= texCd.w;
        
        texCd.y *= -1.;
        texCd.xy += 1.;
        texCd.xy /= 2.;
        
        texCd.xy *= scale;
        texCd.xy += shift;
        
        texCd.xy *= dim;
        gl_TexCoord[0] = texCd;
    }

    scanlineDiscard = sin(frame + pos.y/scanlineDiscardFrequency)*.5 + .5;

//    VZPositionValid0 *= ( sin(frame/4.0 + pos.y) > 0.) ? 1.0 : 0.0;
//    pos.z += sin(frame/4.0 + pos.y/10.0)*20.0;
    //pos.xyz += surfaceNormal * length( texture2DRect(distortTex, gl_Vertex.xy * .2).xyz ) * 100.0;
    //pos.xyz -= surfaceNormal * 20.0;
    
    distortionColorSample.xy = gl_Vertex.xy;
    float distortionAmount = length( texture2DRect(distortTex, distortionColorSample.xy).xyz);
    pos.z -= distortionAmount * distortionScale;

    distortionColorSample.z = distortionAmount;

    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * pos;
    gl_FrontColor = gl_Color;

}
