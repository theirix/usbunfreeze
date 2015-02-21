//
//  main.m
//  usbunfreeze
//
//  Created by Eugene Seliverstov on 14.12.2014.
//  Copyright (c) 2014 omniverse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/usb/IOUSBLib.h>
#import <mach/mach_port.h>
#import "Notification.h"

static void processDevice(struct IOUSBDeviceStruct320 **deviceIntf)
{
    uint32_t portInfo = 0;
    IOReturn error;

    // Get the Port Information
    error = (*deviceIntf)->GetUSBDeviceInformation(deviceIntf, &portInfo);
    if (error == kIOReturnSuccess) {
        if (portInfo & (1 << kUSBInformationDeviceIsSuspendedBit)) {
            NSLog(@"Unfreeze device 0x%x by unsuspending and suspending back", portInfo);

            error = (*deviceIntf)->USBDeviceOpen(deviceIntf);
            if (error != kIOReturnSuccess) {
                NSLog(@"USBDeviceOpen failed for device 0x%x: err 0x%x", portInfo, error);
            }
            else
            {
                error = (*deviceIntf)->USBDeviceSuspend(deviceIntf, false);
                if (error != kIOReturnSuccess) {
                    NSLog(@"Error unsuspending device 0x%x: err 0x%x", portInfo, error);
                }
                error = (*deviceIntf)->USBDeviceSuspend(deviceIntf, true);
                if (error != kIOReturnSuccess) {
                    NSLog(@"Error suspending back device 0x%x: err 0x%x", portInfo, error);
                }

                error = (*deviceIntf)->USBDeviceClose(deviceIntf);
                if (error != kIOReturnSuccess) {
                    NSLog(@"USBDeviceClose failed for device 0x%x: err 0x%x", portInfo, error);
                }
            }

        }
    } else {
        NSLog(@"Error reading device info. Port 0x%x, err 0x%d.", portInfo, error);
    }
}

static void usbUnfreeze()
{
    CFDictionaryRef matchingDict = NULL;
    mach_port_t mMasterDevicePort = MACH_PORT_NULL;
    io_iterator_t devIter = IO_OBJECT_NULL;
    io_service_t ioDeviceObj = IO_OBJECT_NULL;
    IOReturn kr;

    NSLog(@"usbunfreeze started");

    kr = IOMasterPort(MACH_PORT_NULL, &mMasterDevicePort);
    if (kr != kIOReturnSuccess) {
        NSLog(@"USB Prober: error in -refresh at IOMasterPort()");
        return;
    }

    matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
    if (matchingDict == NULL) {
        NSLog(@"USB Prober: error in -refresh at IOServiceMatching() - "
              @"dictionary " @"was NULL");
        mach_port_deallocate(mach_task_self(), mMasterDevicePort);
        return;
    }

    kr = IOServiceGetMatchingServices(mMasterDevicePort, matchingDict /*reference consumed*/, &devIter);
    if (kr != kIOReturnSuccess) {
        NSLog(@"USB Prober: error in -refresh at IOServiceGetMatchingServices()");
        mach_port_deallocate(mach_task_self(), mMasterDevicePort);
        return;
    }

    while ((ioDeviceObj = IOIteratorNext(devIter))) {
        IOCFPlugInInterface **ioPlugin;
        struct IOUSBDeviceStruct320 **deviceIntf = NULL;
        SInt32 score;

        kr = IOCreatePlugInInterfaceForService(
                                               ioDeviceObj, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
                                               &ioPlugin, &score);
        if (kr != kIOReturnSuccess) {
            IOObjectRelease(ioDeviceObj);
            continue;
        }

        kr = (*ioPlugin)->QueryInterface(
                                         ioPlugin, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                         (LPVOID *)&deviceIntf);
        IODestroyPlugInInterface(ioPlugin);
        ioPlugin = NULL;

        if (kr != kIOReturnSuccess) {
            IOObjectRelease(ioDeviceObj);
            continue;
        }

        processDevice(deviceIntf);

        (*deviceIntf)->Release(deviceIntf);
        IOObjectRelease(ioDeviceObj);
    }

    IOObjectRelease(devIter);
    mach_port_deallocate(mach_task_self(), mMasterDevicePort);
    NSLog(@"usbunfreeze finished");
}

int main(int argc, const char * argv[]) {
    usbUnfreeze();
    [[Notification new ]showNotification:@"Unfreeze launched and fixed the laptop" withTitle:@"usbunfreeze"];
    return 0;
}
