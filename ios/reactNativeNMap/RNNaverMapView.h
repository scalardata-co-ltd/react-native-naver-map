//
//  RNNaverMapView.h
//
//  Created by flask on 18/04/2019.
//  Copyright © 2019 flask. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>
#import <React/RCTBridge.h>

#import <NMapsMap/NMFNaverMapView.h>
#import <NMapsGeometry/NMGLatLng.h>
#import <NMapsMap/NMFMarker.h>
#import <NMapsMap/NMFCameraUpdate.h>
#import <NMapsMap/NMFMapViewDelegate.h>
#import <NMapsMap/NMFMapViewTouchDelegate.h>
#import <NMapsMap/NMFMapViewOptionDelegate.h>
#import <NMapsMap/NMFMapViewCameraDelegate.h>

#import "RCTConvert+NMFMapView.h"

@interface RNNaverMapView : NMFNaverMapView <NMFMapViewCameraDelegate, NMFMapViewOptionDelegate, NMFMapViewTouchDelegate>

@property (nonatomic, weak) RCTBridge *bridge;
@property (nonatomic, copy) RCTDirectEventBlock onInitialized;
@property (nonatomic, copy) RCTDirectEventBlock onCameraChange;
@property (nonatomic, copy) RCTDirectEventBlock onMove;
@property (nonatomic, copy) RCTDirectEventBlock onMapClick;
@property (nonatomic, copy) RCTDirectEventBlock onChangeLocationTrackingMode;

@property (nonatomic, assign) BOOL showsCompass;
@property (nonatomic, assign) BOOL zoomEnabled;
@property (nonatomic, assign) BOOL showsMyLocationButton;
@property (nonatomic, strong) NSTimer *debounceTimer;

- (void)debounceApplyPendingCamera;
- (void)applyPendingCameraIfNeeded;

@end
