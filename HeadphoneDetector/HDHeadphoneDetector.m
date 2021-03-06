//
//  HDHeadphoneDetector.m
//  CrimePrevention
//
//  Created by MIYAMOTO TATSUYA on 2013/05/26.
//  Copyright (c) 2013年 MIYAMOTO TATSUYA. All rights reserved.
//
#import "HDHeadphoneDetector.h"

void audioRouteChangeListenerCallback(void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertySize, const void *inPropertyValue);

@implementation HDHeadphoneDetector
@synthesize currenstateArePlugged;
#pragma mark- Life Circle
+(HDHeadphoneDetector *)sharedDetector
{
    static HDHeadphoneDetector *detector;
    if(detector == nil)
    {
        @synchronized([self class])
        {
            if(detector == nil)
            {
                detector = [[HDHeadphoneDetector alloc] init];
            }
        }
    }
    return detector;
}

- (id)init
{
	self = [super init];
	if (self)
    {
		AudioSessionInitialize(NULL, NULL, NULL, NULL);
		AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, ( void *)self);
	}
	return self;
}

- (void) dealloc
{
	AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, ( void *)self);
    
    [super dealloc];
}

#pragma mark- Public Methods
-(BOOL) currenstateArePlugged
{
	// thanks to: http://blog.csdn.net/ysy441088327/article/details/8164120
	BOOL result = NO;
    
	CFStringRef route;
	UInt32 propertySize = sizeof(CFStringRef);
	if (AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &route) == 0)
    {
        NSString *routeString = (NSString *)route;
        DLog(@"routeString is %@", routeString)
        
        /* Known values of route:
         * "Headset"
         * "Headphone"
         * "Speaker"
         * "SpeakerAndMicrophone"
         * "HeadphonesAndMicrophone"
         * "HeadsetInOut"
         * "ReceiverAndMicrophone"
         * "Lineout"
         */
        
        NSRange headphoneRange = [routeString rangeOfString : @"Headphone"];
        NSRange headsetRange = [routeString rangeOfString : @"Headset"];
        
        if(headphoneRange.location != NSNotFound)
        {
            result = YES;
        }
        else if (headsetRange.location != NSNotFound)
        {
            result = YES;
        }
        else
        {
            result = NO;
        }
	}
	return result;
}

- (void) headphoneArePlugged
{
	[[NSNotificationCenter defaultCenter] postNotificationName:HEADPHONE_PLUGGED object:self];
}

- (void) headphoneAreNotPlugged
{
	[[NSNotificationCenter defaultCenter] postNotificationName:HEADPHONE_NOT_PLUGGED object:self];
}

/*
 -(void)headphoneIsPlugged
 {
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
 }
 
 -(void)headphoneIsNotPlugged
 {
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
 }
 */

#pragma mark- Listener Call Back
void audioRouteChangeListenerCallback(void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertySize, const void *inPropertyValue)
{
	if( inPropertyID != kAudioSessionProperty_AudioRouteChange)
    {
		return;
	}

	CFDictionaryRef routeChangeDictionary = inPropertyValue;

	CFNumberRef routeChangeReasonRef = CFDictionaryGetValue(routeChangeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
	SInt32 routeChangeReason;
	CFNumberGetValue(routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason);

	if( routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable || routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable)
    {
		CFStringRef route;
		UInt32 propertySize = sizeof(CFStringRef);
        
		if(AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &route) == 0)
        {
            HDHeadphoneDetector *headphoneDetector = (HDHeadphoneDetector *)inUserData;
            NSString *routeString = (NSString *)route;
            DLog(@"routeString is %@", routeString)
            
            /* Known values of route:
             * "Headset"
             * "Headphone"
             * "Speaker"
             * "SpeakerAndMicrophone"
             * "HeadphonesAndMicrophone"
             * "HeadsetInOut"
             * "ReceiverAndMicrophone"
             * "Lineout"
             */
            
            NSRange headphoneRange = [routeString rangeOfString : @"Headphone"];
            NSRange headsetRange = [routeString rangeOfString : @"Headset"];

            if(headphoneRange.location != NSNotFound)
            {
                [headphoneDetector headphoneArePlugged];
            }
            else if (headsetRange.location != NSNotFound)
            {
                [headphoneDetector headphoneArePlugged];
            }
            else
            {
                [headphoneDetector headphoneAreNotPlugged];
            }
		}
	}
}

@end