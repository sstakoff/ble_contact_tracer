#import "BleContactTracerPlugin.h"
#if __has_include(<ble_contact_tracer/ble_contact_tracer-Swift.h>)
#import <ble_contact_tracer/ble_contact_tracer-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ble_contact_tracer-Swift.h"
#endif

@implementation BleContactTracerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftBleContactTracerPlugin registerWithRegistrar:registrar];
}
@end
