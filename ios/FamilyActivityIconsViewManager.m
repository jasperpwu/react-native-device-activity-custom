//
//  FamilyActivityIconsViewManager.m
//  react-native-device-activity
//
//  Created by ReactNativeDeviceActivity on 2024.
//

#import "React/RCTViewManager.h"

@interface RCT_EXTERN_MODULE(FamilyActivityIconsViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(familyActivitySelection, NSString)
RCT_EXPORT_VIEW_PROPERTY(maxDisplayedIcons, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(iconSize, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(showOverflow, BOOL)

@end