#version 110
#extension GL_ARB_texture_rectangle : enable

uniform sampler2DRect colorTex;
uniform sampler2DRect faceTex;
uniform sampler2DRect distortTex;

uniform float distortionSampleAmount;

uniform int useTexture;
varying float VZPositionValid0;
varying vec3 normal;
const float epsilon = 1e-6;

varying vec3 distortionColorSample;

uniform float scanlineDiscardThreshold;
varying float scanlineDiscard;

uniform float depthColorMix;
varying float depthColor;

varying vec3 lightDir, eyeVec;
varying float att;

vec4 calculateLight(float faceAttenuate){

	vec3 N = normalize(normal);
	vec3 L = normalize(lightDir);
	
	float lambertTerm = dot(N,L) * att;
    return vec4(vec3(mix(lambertTerm, 1.0, 0.0)), 1.0);

	//return vec4(vec3(mix(lambertTerm, 1.0, faceAttenuate)), 1.0);

}

void main()
{
    if(VZPositionValid0 < epsilon || scanlineDiscard < (scanlineDiscardThreshold+epsilon)){
    	discard;
        return;
    }

    vec4 faceAttenuation = texture2DRect(faceTex, gl_TexCoord[0].st);
    if(useTexture == 1){
        vec4 col = texture2DRect(colorTex, gl_TexCoord[0].st);
        vec4 distortionColor = texture2DRect(distortTex, distortionColorSample.xy);
        col = mix(col, distortionColor, distortionSampleAmount * (1.0 - ( pow(1.0 - distortionColorSample.z, 3.0) )) ) ;
        col = mix(col, vec4(vec3(depthColor), 1.0), depthColorMix);
        gl_FragData[0] = col * calculateLight(faceAttenuation.b) * gl_Color;

        //gl_FragData[0] = vec4(faceAttenuation.b);
    }
    else{
        gl_FragData[0] = vec4(0);
    }    

    //blue for face, red for eyes
    gl_FragData[1] = vec4( normal * (1.0 - faceAttenuation.b) , 1.0 ) ;
    
    //gl_FragData[1] = vec4( normal, 1.0 ) ;
    //gl_FragData[0] = vec4(1.0, 0.0, 0.0, 1.0);
    //gl_FragColor = vec4(VZPositionValid0);
    //gl_FragColor.z = 1.0;
}