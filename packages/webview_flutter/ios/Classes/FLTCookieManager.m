// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTCookieManager.h"
#import "CookieDto.h"

@implementation FLTCookieManager {
}

NSSet *websiteDataTypes;
API_AVAILABLE(ios(9.0))
WKWebsiteDataStore *dataStore;
API_AVAILABLE(ios(11.0))
WKHTTPCookieStore *cookieStore;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FLTCookieManager *instance = [[FLTCookieManager alloc] init];

  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/cookie_manager"
                                  binaryMessenger:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:channel];

  if (@available(iOS 11.0, *)) {
    websiteDataTypes = [NSSet setWithArray:@[ WKWebsiteDataTypeCookies ]];
    dataStore = [WKWebsiteDataStore defaultDataStore];
    cookieStore = [dataStore httpCookieStore];
  } else {
    NSLog(@"This plugin is not supported for iOS versions prior to iOS 11.");
  }
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result API_AVAILABLE(ios(11.0)) {
  if ([[call method] isEqualToString:@"clearCookies"]) {
    [self clearCookies:result];
  } else if ([[call method] isEqualToString:@"getCookies"]) {
    [self getCookies:result];
  } else if ([[call method] isEqualToString:@"setCookies"]) {
    [self setCookies:call result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)clearCookies:(FlutterResult)result {
  if (@available(iOS 9.0, *)) {
    NSSet<NSString *> *websiteDataTypes = [NSSet setWithObject:WKWebsiteDataTypeCookies];
    WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];

    void (^deleteAndNotify)(NSArray<WKWebsiteDataRecord *> *) =
        ^(NSArray<WKWebsiteDataRecord *> *cookies) {
          BOOL hasCookies = cookies.count > 0;
          [dataStore removeDataOfTypes:websiteDataTypes
                        forDataRecords:cookies
                     completionHandler:^{
                       result(@(hasCookies));
                     }];
        };

    [dataStore fetchDataRecordsOfTypes:websiteDataTypes completionHandler:deleteAndNotify];
  } else {
    // support for iOS8 tracked in https://github.com/flutter/flutter/issues/27624.
    NSLog(@"Clearing cookies is not supported for Flutter WebViews prior to iOS 9.");
  }
}

- (void)getCookies:(FlutterResult)result API_AVAILABLE(ios(11.0)) {
  [cookieStore getAllCookies:^(NSArray<NSHTTPCookie *> *cookies) {
    NSArray *serialized = [CookieDto manyToDictionary:[CookieDto manyFromNSHTTPCookies:cookies]];
    result(serialized);
  }];
}

- (void)setCookies:(FlutterMethodCall *)call result:(FlutterResult)result API_AVAILABLE(ios(11.0)) {
  NSArray<CookieDto *> *cookieDtos = [CookieDto manyFromDictionaries:[call arguments]];
  for (CookieDto *cookieDto in cookieDtos) {
    [cookieStore setCookie:[cookieDto toNSHTTPCookie]
         completionHandler:^(){
         }];
  }
}

- (void)clearCookies:(FlutterResult)result API_AVAILABLE(ios(11.0)) {
  [cookieStore getAllCookies:^(NSArray<NSHTTPCookie *> *allCookies) {
    for (NSHTTPCookie *cookie in allCookies) {
      [cookieStore deleteCookie:cookie
              completionHandler:^(){
              }];
    }
  }];
}

@end
