// -------------------------------------------------------------------------------------------------
//  HelloLightingLayer.m
//  LightTest
//
//  Created by Capsaic (SmashRiot.com | @SmashRiot) on 2013/08/12.
//  Copyright (c) 2013 Capsaic
//
// * "THE BEER-WARE LICENSE" (Revision 42):
// * Jesse Ozog <capsaic@SmashRiot.com> wrote this file. As long as you retain this notice you
// * can do whatever you want with this stuff. If we meet some day, and you think
// * this stuff is worth it, you can buy me a beer in return. Jesse Ozog
//
// Note, this project is based on a default cocos2d 2.0 ios project in xcode
// -------------------------------------------------------------------------------------------------

// Import the interfaces
#import "HelloLightingLayer.h"

#pragma mark - HelloLightingLayer

// -------------------------------------------------------------------------------------------------
// HelloLightingLayer implementation
// -------------------------------------------------------------------------------------------------
@implementation HelloLightingLayer

// Helper class method that creates a Scene with the HelloLightingLayer as the only child.
+(CCScene *) scene;
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloLightingLayer *layer = [HelloLightingLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// -------------------------------------------------------------------------------------------------
// on "init" you need to initialize your instance
// -------------------------------------------------------------------------------------------------
-(id) init;
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
        
        // set lighting defaults
        lightPos = ccp(0,0);
        lightFalloff = LIGHTING_FALLOFF;
        lightIntensity = LIGHTING_INTENSITY;

        // add shader program
        [self addLightingBlurShader:lightPos falloff:lightFalloff intensity:lightIntensity];
        
        // texture for the batch sheet
        CCTexture2D *textureSheet = [[CCTextureCache sharedTextureCache] addImage:TILE_IMAGE];
        [textureSheet setAliasTexParameters];
        
        // add batch node. capacity is set at tiles wide*tiles high
        background = [CCSpriteBatchNode batchNodeWithTexture:textureSheet capacity:(TILES_HIGH*TILES_WIDE)];
        [background setPosition:ccp(0,0)];
        [background setAnchorPoint:ccp(0,0)];
        background.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:@"LightingBlurShader"]; 
        
        // add the batch node to the layer
        [self addChild: background];
        
        // add some tiles to the batch node
        for (int y=0; y<TILES_HIGH; y++){
            for (int x=0; x<TILES_WIDE; x++){
                CCSprite *tileSprite = [CCSprite spriteWithFile:TILE_IMAGE];
                [tileSprite setPosition:ccp(x*TILE_IMAGE_WIDTH,y*TILE_IMAGE_HEIGHT)];
                [tileSprite setAnchorPoint:ccp(0,0)];
                [background addChild:tileSprite];
                tileSprite = nil;
            }
        }

        // update light pos 30x sec
        [self schedule:@selector(lightPosUpdate:) interval:1/30];
        
        // cleanup
        textureSheet = nil;
	}
	return self;
}

// -------------------------------------------------------------------------------------------------
// on "dealloc" you need to release all your retained objects
// -------------------------------------------------------------------------------------------------
-(void) dealloc;
{
	// cleanup
    [self unschedule:@selector(lightPosUpdate:)];
    background = nil;
    [self removeAllChildrenWithCleanup:YES];
    
	// don't forget to call "super dealloc"
	[super dealloc];
}

// -------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------
-(void) lightPosUpdate: (ccTime) dt;
{
    // set active shader
    [background.shaderProgram use];  // set shader active/in use

    // move light across background diagonally in LIGHTING_FRAMES steps
    CGSize size = [[CCDirector sharedDirector] winSize];
    lightPos.x += size.width / LIGHTING_FRAMES;
    lightPos.y += size.height / LIGHTING_FRAMES;
    
    // wrap back to 0,0 after it goes off the screen
    if (lightPos.x > size.width && lightPos.y > size.height){
        lightPos.x -= size.width; 
        lightPos.y -= size.height;
        
        // reset intensity
        lightFalloff = LIGHTING_FALLOFF;
        lightIntensity = LIGHTING_INTENSITY;
    }
    
    // move light across background diagonally from bottom left to top right
    GLint lightPositionUniformLocation = glGetUniformLocation(background.shaderProgram->program_, "u_lightPosition");
    glUniform4f(lightPositionUniformLocation, lightPos.x, lightPos.y, 0.0f, 0.0f); // set var in active shader
    CHECK_GL_ERROR_DEBUG();
    
    // increasing falloff makes the light drop to darkness faster
    lightFalloff += LIGHTING_FALLOFF_STEP;
    GLint lightFalloffUniformLocation = glGetUniformLocation(background.shaderProgram->program_, "u_lightFalloff");
    glUniform1f(lightFalloffUniformLocation, lightFalloff);
    CHECK_GL_ERROR_DEBUG();

    // decreasing the intensity makes the center spot less bright
    lightIntensity -= LIGHTING_INTENSITY_STEP;
    GLint lightIntensityUniformLocation = glGetUniformLocation(background.shaderProgram->program_, "u_lightIntensity");
    glUniform1f(lightIntensityUniformLocation, lightIntensity);
    CHECK_GL_ERROR_DEBUG();

    // show values if debugging
    if (LIGHT_DEBUG) NSLog(@"lightPosUpdate: LightPos[%1.0f,%1.0f], Falloff[%1.8f], Intensity[%1.3f]",
                           lightPos.x, lightPos.y, lightFalloff, lightIntensity);
}

// -------------------------------------------------------------------------------------------------
// LIGHT+BLUR FRAGMENT SHADER
// -------------------------------------------------------------------------------------------------
const GLchar *Shaders_lightingBlur_frag =
"varying lowp vec3 v_fragmentColor;                                                                        \n\
varying lowp vec2 v_texCoord;                                                                              \n\
varying lowp vec2 v_textCoordL;                                                                            \n\
varying lowp vec2 v_textCoordR;                                                                            \n\
                                                                                                           \n\
uniform sampler2D u_texture;                                                                               \n\
                                                                                                           \n\
void main()                                                                                                \n\
{                                                                                                          \n\
    // sample texture                                                                                      \n\
    lowp vec4 fragColor = texture2D(u_texture, v_texCoord);                                                \n\
    lowp vec4 fragBlur = max(texture2D(u_texture, v_textCoordL), texture2D(u_texture, v_textCoordR));      \n\
                                                                                                           \n\
    // set the color to fragment tint color * native fragment color                                        \n\
    gl_FragColor = vec4(fragColor.a * v_fragmentColor * (fragColor.rgb + fragBlur.rgb), fragColor.a);      \n\
}";

// -------------------------------------------------------------------------------------------------
// LIGHT+BLUR VERTEX SHADER
// -------------------------------------------------------------------------------------------------
const GLchar *Shaders_lightingBlur_vert =
"attribute vec4 a_position;                                                                                \n\
attribute vec2 a_texCoord;                                                                                 \n\
attribute vec4 a_color;								                                                       \n\
                                                                                                           \n\
uniform	mat4 u_MVPMatrix;                                                                                  \n\
uniform vec4 u_lightPosition;                                                                              \n\
uniform float u_lightFalloff;                                                                              \n\
uniform float u_lightIntensity;                                                                            \n\
                                                                                                           \n\
varying lowp vec2 v_texCoord;                                                                              \n\
varying lowp vec2 v_textCoordL;                                                                            \n\
varying lowp vec2 v_textCoordR;                                                                            \n\
varying lowp vec3 v_fragmentColor;					                                                       \n\
                                                                                                           \n\
void main()											                                                       \n\
{													                                                       \n\
    // positions - transform to eye space to MVPMatrix                                                     \n\
    gl_Position = u_MVPMatrix * a_position;			                                                       \n\
                                                                                                           \n\
    // calc light dist                                                                                     \n\
    mediump float lightDistance = distance(a_position, u_lightPosition);                                   \n\
                                                                                                           \n\
    // falloff 0.00005 = dark, 0.000005 = light                                                            \n\
    lowp float lightValue = (1.0 / (1.0 + (u_lightFalloff * lightDistance * lightDistance)));              \n\
                                                                                                           \n\
    // set frag color with lighting                                                                        \n\
    v_fragmentColor = a_color.rgb * (lightValue * u_lightIntensity);                                       \n\
                                                                                                           \n\
    // coordinates                                                                                         \n\
    v_texCoord = a_texCoord;                                                                               \n\
    v_textCoordL = vec2(a_texCoord.x-0.00390625, a_texCoord.y);                                            \n\
    v_textCoordR = vec2(a_texCoord.x+0.00390625, a_texCoord.y);                                            \n\
}";

// -------------------------------------------------------------------------------------------------
// SHADER PROGRAM: BLUR + LIGHT
// -------------------------------------------------------------------------------------------------
-(void) addLightingBlurShader:(CGPoint) initialLightPosition falloff:(float) initialLightFalloff intensity:(float) initialLightIntensity;
{
    // define the default shader program
	CCGLProgram *shaderProgram = [[CCGLProgram alloc] initWithVertexShaderByteArray:Shaders_lightingBlur_vert
                                                            fragmentShaderByteArray:Shaders_lightingBlur_frag];
    CHECK_GL_ERROR_DEBUG();
    
	[shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
    CHECK_GL_ERROR_DEBUG();
	[shaderProgram addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
    CHECK_GL_ERROR_DEBUG();
	[shaderProgram addAttribute:kCCAttributeNameColor index:kCCVertexAttrib_Color];
    CHECK_GL_ERROR_DEBUG();
    
	[shaderProgram link];
    CHECK_GL_ERROR_DEBUG();
    
	[shaderProgram updateUniforms];
    CHECK_GL_ERROR_DEBUG();
    
    [[CCShaderCache sharedShaderCache] addProgram:shaderProgram forKey:@"LightingBlurShader"];
    CHECK_GL_ERROR_DEBUG();
    
    // set initial light position
    GLint lightPositionUniformLocation = glGetUniformLocation(shaderProgram->program_, "u_lightPosition");
    glUniform4f(lightPositionUniformLocation, initialLightPosition.x, initialLightPosition.y, 0.0f, 0.0f); 
    CHECK_GL_ERROR_DEBUG();

    // set initial light falloff
    GLint lightFalloffUniformLocation = glGetUniformLocation(shaderProgram->program_, "u_lightFalloff");
    glUniform1f(lightFalloffUniformLocation, initialLightFalloff);
    CHECK_GL_ERROR_DEBUG();
    
    // set initial light intensity
    GLint lightIntensityUniformLocation = glGetUniformLocation(shaderProgram->program_, "u_lightIntensity");
    glUniform1f(lightIntensityUniformLocation, initialLightIntensity); 
    CHECK_GL_ERROR_DEBUG();
    
	[shaderProgram release];
    shaderProgram = nil;
}

@end