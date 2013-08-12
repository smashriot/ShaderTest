// -------------------------------------------------------------------------------------------------
//  HelloLightingLayer.h
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
// Note, set #define CC_ENABLE_GL_STATE_CACHE 1 in ccConfig.h
// -------------------------------------------------------------------------------------------------

#import "cocos2d.h"

// lighting defines
#define LIGHTING_INTENSITY 1.5
#define LIGHTING_INTENSITY_STEP 0.005
#define LIGHTING_FALLOFF 0.00005
#define LIGHTING_FALLOFF_STEP 0.000001
#define LIGHTING_FRAMES 300
// sprite is 50x50. ipad is 1024x768 = 20.5x15.4 tiles
#define TILES_HIGH 16
#define TILES_WIDE 21
#define TILE_IMAGE @"Icon-Small-50.png"
#define TILE_IMAGE_WIDTH 50
#define TILE_IMAGE_HEIGHT 50
// debug
#define LIGHT_DEBUG TRUE

// HelloLightingLayer
@interface HelloLightingLayer : CCLayer
{
    CGPoint lightPos;
    float lightFalloff;
    float lightIntensity;
    CCSpriteBatchNode *background;
}

// grep "^[-|+]" HelloLightingLayer.m
+(CCScene *) scene;
-(id) init;
-(void) dealloc;
-(void) lightPosUpdate: (ccTime) dt;
-(void) addLightingBlurShader:(CGPoint) initialLightPosition falloff:(float) initialLightFalloff intensity:(float) initialLightIntensity;

@end