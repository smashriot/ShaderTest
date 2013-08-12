// -------------------------------------------------------------------------------------------------
//  SRShaders.h
//  TRISECTOR
//
//  Created by Jesse Ozog on 3/8/2013.
//  Copyright (c) 2012-2013 SmashRiot.com. All rights reserved.
// -------------------------------------------------------------------------------------------------
#import "SRShaders.h"

// lighting
#define GLOBAL_SHADER_DEBUG TRUE
#define LIGHTING_BASE_INTENSITY 1.5
#define LIGHTING_BASE_FALLOFF 0.000025

// -------------------------------------------------------------------------------------------------
// BASE LAYER FRAG: BLUR + LIGHT
// -------------------------------------------------------------------------------------------------
const GLchar *Shaders_lightingBlur_frag =
"varying lowp vec3 v_fragmentColor;                                                                         \n\
varying lowp vec2 v_texCoord;                                                                               \n\
varying lowp vec2 v_textCoordL;                                                                             \n\
varying lowp vec2 v_textCoordR;                                                                             \n\
                                                                                                            \n\
uniform sampler2D u_texture;                                                                                \n\
                                                                                                            \n\
void main()                                                                                                 \n\
{                                                                                                           \n\
    // sample texture                                                                                       \n\
    lowp vec4 fragColor = texture2D(u_texture, v_texCoord);                                                 \n\
    lowp vec4 fragBlur = max(texture2D(u_texture, v_textCoordL), texture2D(u_texture, v_textCoordR));       \n\
                                                                                                            \n\
    // set the color to fragment tint color * native fragment color                                         \n\
    gl_FragColor = vec4(fragColor.a * v_fragmentColor * (fragColor.rgb + fragBlur.rgb), fragColor.a);       \n\
}";

// -------------------------------------------------------------------------------------------------
// BASE LAYER VERT: BLUR + LIGHT
// -------------------------------------------------------------------------------------------------
const GLchar *Shaders_lightingBlur_vert =
"attribute vec4 a_position;                                                             \n\
attribute vec2 a_texCoord;                                                              \n\
attribute vec4 a_color;								                                    \n\
                                                                                        \n\
uniform	mat4 u_MVPMatrix;                                                               \n\
uniform vec4 u_lightPosition;                                                           \n\
uniform float u_lightFalloff;                                                           \n\
uniform float u_lightIntensity;                                                         \n\
                                                                                        \n\
varying lowp vec2 v_texCoord;                                                           \n\
varying lowp vec2 v_textCoordL;                                                         \n\
varying lowp vec2 v_textCoordR;                                                         \n\
varying lowp vec3 v_fragmentColor;					                                    \n\
                                                                                        \n\
void main()											                                    \n\
{													                                    \n\
    // positions - transform to eye space to MVPMatrix                                  \n\
    gl_Position = u_MVPMatrix * a_position;			                                    \n\
                                                                                        \n\
    // calc light dist                                                                  \n\
    mediump float lightDistance = distance(a_position, u_lightPosition);                \n\
                                                                                        \n\
    // rate: 0.00005 = dark, 0.000005 = light, 0.00009 = good                           \n\
    lowp float lightValue = (1.0 / (1.0 + (u_lightFalloff * lightDistance * lightDistance)));      \n\
                                                                                        \n\
    // pre-mul (0.75 * 0.5) in the lightcolor to save a mul in frag shader              \n\
    //v_fragmentColor = 0.375 * a_color.rgb * lightValue * u_lightIntensity;            \n\
    v_fragmentColor = a_color.rgb * (lightValue * u_lightIntensity);                    \n\
                                                                                        \n\
    // coordinates                                                                      \n\
    v_texCoord = a_texCoord;                                                            \n\
    v_textCoordL = vec2(a_texCoord.x-0.00390625, a_texCoord.y);                         \n\
    v_textCoordR = vec2(a_texCoord.x+0.00390625, a_texCoord.y);                         \n\
}";

// -------------------------------------------------------------------------------------------------
// BASE LAYER: BLUR + LIGHT
// -------------------------------------------------------------------------------------------------
void addLightingBaseLayerShader()
{
    // define the default shader program
	CCGLProgram *shaderProgram = [[CCGLProgram alloc] initWithVertexShaderByteArray:Shaders_lightingBlur_vert
                                                            fragmentShaderByteArray:Shaders_lightingBlur_frag];
    if (GLOBAL_SHADER_DEBUG) CHECK_GL_ERROR_DEBUG();
    
	[shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
	[shaderProgram addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
	[shaderProgram addAttribute:kCCAttributeNameColor index:kCCVertexAttrib_Color];
    if (GLOBAL_SHADER_DEBUG) CHECK_GL_ERROR_DEBUG();
    
	[shaderProgram link];
    if (GLOBAL_SHADER_DEBUG) CHECK_GL_ERROR_DEBUG();
    
	[shaderProgram updateUniforms];
    if (GLOBAL_SHADER_DEBUG) CHECK_GL_ERROR_DEBUG();
    
    [[CCShaderCache sharedShaderCache] addProgram:shaderProgram forKey:@"LightingBaseShader"];
    if (GLOBAL_SHADER_DEBUG) CHECK_GL_ERROR_DEBUG();
    
    // set lighting vars defaults
    GLint lightFalloffUniformLocation = glGetUniformLocation(shaderProgram->program_, "u_lightFalloff");
    glUniform1f(lightFalloffUniformLocation, LIGHTING_BASE_FALLOFF);
    GLint lightIntensityUniformLocation = glGetUniformLocation(shaderProgram->program_, "u_lightIntensity");
    glUniform1f(lightIntensityUniformLocation, LIGHTING_BASE_INTENSITY); // should be *0.5 normal values since avg of 2 pixels
    
	[shaderProgram release];
    shaderProgram = nil;
}
