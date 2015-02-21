//
//  Notification.m
//  usbunfreeze
//
//  Created by Eugene Seliverstov on 22.02.2015.
//  Copyright (c) 2015 omniverse. All rights reserved.
//

#import "Notification.h"
#import <objc/runtime.h>

@implementation NSBundle(FakeBundleIdentifier)

-(NSString*) __bundleIdentifier {
    if (self == [NSBundle mainBundle]) {
        return @"com.apple.terminal";
    } else {
        return [self __bundleIdentifier];
    }
}

@end

@implementation FakeBundle

+(BOOL) installNSBundleHook {
    Class clazz = objc_getClass("NSBundle");
    if (clazz) {
        method_exchangeImplementations(class_getInstanceMethod(clazz, @selector(bundleIdentifier)),
                                       class_getInstanceMethod(clazz, @selector(__bundleIdentifier)));
        return YES;
    }
    return NO;
}

@end


@implementation Notification

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    exit(0);
}

- (void)showNotification:(NSString*)text withTitle:(NSString*)title {
    if (![FakeBundle installNSBundleHook])
        return;

    NSUserNotification *userNotification = [NSUserNotification new];
    userNotification.title = title;
    userNotification.informativeText = text;
    userNotification.soundName = NSUserNotificationDefaultSoundName;
    userNotification.hasActionButton = NO;
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    center.delegate = self;
    [center deliverNotification:userNotification];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: 30]];
}
@end

