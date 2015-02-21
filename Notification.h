//
//  Notification.h
//  usbunfreeze
//
//  Created by Eugene Seliverstov on 22.02.2015.
//  Copyright (c) 2015 omniverse. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// A fake bundle
@interface FakeBundle : NSObject

+(BOOL) installNSBundleHook;

@end

// An app delegate to react to notification display

@interface Notification : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>

- (void)showNotification:(NSString*)text withTitle:(NSString*)title;
    
@end
