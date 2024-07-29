//
//  RNNaverMapView.m
//
//  Created by flask on 18/04/2019.
//  Copyright © 2019 flask. All rights reserved.
//

#import "RNNaverMapView.h"
#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>
#import <React/RCTBridge.h>
#import <React/UIView+React.h>

#import <NMapsGeometry/NMGLatLng.h>
#import <NMapsMap/NMFMarker.h>
#import <NMapsMap/NMFCameraUpdate.h>
#import <NMapsMap/NMFCameraPosition.h>

#import "RCTConvert+NMFMapView.h"
#import "RNNaverMapMarker.h"
#import "RNNaverMapPolylineOverlay.h"
#import "RNNaverMapPathOverlay.h"
#import "RNNaverMapCircleOverlay.h"
#import "RNNaverMapPolygonOverlay.h"

@interface RNNaverMapView()
@end

@implementation RNNaverMapView
{
  NSMutableArray<UIView *> *_reactSubviews;
  BOOL _initialCameraSet;
}

- (nonnull instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    _reactSubviews = [NSMutableArray new];
  }
  _initialCameraSet = NO;

  return self;
}
- (void)applyPendingCameraIfNeeded {
  if (_initialCameraSet || self.mapView.frame.size.width <= 0 || self.mapView.frame.size.height <= 0) {
    return;
  }

  NMFCameraPosition *prev = self.mapView.cameraPosition;

  double latitude = prev.target.lat;
  double longitude = prev.target.lng;
  double zoom = 14.5;

  NMGLatLng* target = [NMGLatLng latLngWithLat:latitude lng:longitude];
  NMFCameraPosition* cameraPosition = [NMFCameraPosition cameraPosition:target zoom:zoom];
  NMFCameraUpdate* cameraUpdate = [NMFCameraUpdate cameraUpdateWithPosition:cameraPosition];

  [self.mapView moveCamera:cameraUpdate];
  _initialCameraSet = YES;

}

- (void)debounceApplyPendingCamera {
    [self.debounceTimer invalidate];
    self.debounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                          target:self
                                                        selector:@selector(applyPendingCameraIfNeeded)
                                                        userInfo:nil
                                                         repeats:NO];
}

- (void)insertReactSubview:(id<RCTComponent>)subview atIndex:(NSInteger)atIndex {
  // Our desired API is to pass up markers/overlays as children to the mapview component.
  // This is where we intercept them and do the appropriate underlying mapview action.
  if ([subview isKindOfClass:[RNNaverMapMarker class]]) {
    RNNaverMapMarker *marker = (RNNaverMapMarker*)subview;
    marker.realMarker.mapView = self.mapView;
  } else if ([subview isKindOfClass:[RNNaverMapPolylineOverlay class]]) {
    RNNaverMapPolylineOverlay *overlay = (RNNaverMapPolylineOverlay*)subview;
    overlay.realOverlay.mapView = self.mapView;
  } else if ([subview isKindOfClass:[RNNaverMapPathOverlay class]]) {
    RNNaverMapPathOverlay *overlay = (RNNaverMapPathOverlay*)subview;
    overlay.realOverlay.mapView = self.mapView;
  } else if ([subview isKindOfClass:[RNNaverMapCircleOverlay class]]) {
    RNNaverMapCircleOverlay *overlay = (RNNaverMapCircleOverlay*)subview;
    overlay.realOverlay.mapView = self.mapView;
  } else if ([subview isKindOfClass:[RNNaverMapPolygonOverlay class]]) {
     RNNaverMapPolygonOverlay *overlay = (RNNaverMapPolygonOverlay*)subview;
     overlay.realOverlay.mapView = self.mapView;
  } else {
    NSArray<id<RCTComponent>> *childSubviews = [subview reactSubviews];
    for (int i = 0; i < childSubviews.count; i++) {
      [self insertReactSubview:(UIView *)childSubviews[i] atIndex:atIndex];
    }
  }
  [_reactSubviews insertObject:(UIView *)subview atIndex:(NSUInteger) atIndex];
}

- (void)removeReactSubview:(id<RCTComponent>)subview {
  // similarly, when the children are being removed we have to do the appropriate
  // underlying mapview action here.
  if ([subview isKindOfClass:[RNNaverMapMarker class]]) {
    RNNaverMapMarker *marker = (RNNaverMapMarker*)subview;
    marker.realMarker.mapView = nil;
  } else if ([subview isKindOfClass:[RNNaverMapPolylineOverlay class]]) {
    RNNaverMapPolylineOverlay *overlay = (RNNaverMapPolylineOverlay*)subview;
    overlay.realOverlay.mapView = nil;
  } else if ([subview isKindOfClass:[RNNaverMapPathOverlay class]]) {
    RNNaverMapPathOverlay *overlay = (RNNaverMapPathOverlay*)subview;
    overlay.realOverlay.mapView = nil;
  } else if ([subview isKindOfClass:[RNNaverMapCircleOverlay class]]) {
    RNNaverMapCircleOverlay *overlay = (RNNaverMapCircleOverlay*)subview;
    overlay.realOverlay.mapView = nil;
  } else if ([subview isKindOfClass:[RNNaverMapPolygonOverlay class]]) {
    RNNaverMapPolygonOverlay *overlay = (RNNaverMapPolygonOverlay*)subview;
    overlay.realOverlay.mapView = nil;
  } else {
    NSArray<id<RCTComponent>> *childSubviews = [subview reactSubviews];
    for (int i = 0; i < childSubviews.count; i++) {
      [self removeReactSubview:(UIView *)childSubviews[i]];
    }
  }
  [_reactSubviews removeObject:(UIView *)subview];
}

- (NSArray<id<RCTComponent>> *)reactSubviews {
  return _reactSubviews;
}

- (void)mapViewIdle:(nonnull NMFMapView *)mapView {
    [self debounceApplyPendingCamera];

    if (((RNNaverMapView*)self).onCameraChange != nil) {
        ((RNNaverMapView*)self).onCameraChange(@{
            @"latitude"      : @(mapView.cameraPosition.target.lat),
            @"longitude"     : @(mapView.cameraPosition.target.lng),
            @"zoom"          : @(mapView.cameraPosition.zoom),
            @"contentRegion" : pointsToJson(mapView.contentRegion.exteriorRing.points),
            @"coveringRegion": pointsToJson(mapView.coveringRegion.exteriorRing.points),
        });
    }
}

static NSArray* pointsToJson(NSArray<NMGLatLng*> *points) {
  NSMutableArray *array = [NSMutableArray array];
  for (int i = 0; i < points.count; i++)
    [array addObject: toJson(points[i])];
  return array;
}

static NSDictionary* toJson(NMGLatLng * _Nonnull latlng) {
   return @{
    @"latitude" : @(latlng.lat),
    @"longitude": @(latlng.lng),
  };
}

- (void)didTapMapView:(CGPoint)point LatLng:(NMGLatLng *)latlng {
  if (((RNNaverMapView*)self).onMapClick != nil)
    ((RNNaverMapView*)self).onMapClick(@{
      @"x"        : @(point.x),
      @"y"        : @(point.y),
      @"latitude" : @(latlng.lat),
      @"longitude": @(latlng.lng)
    });
}

- (void)dealloc {
    [self.debounceTimer invalidate];
}

- (void)mapView:(nonnull NMFMapView *)mapView regionWillChangeAnimated:(BOOL)animated byReason:(NSInteger)reason {
  if (((RNNaverMapView*)self).onMove != nil)
    ((RNNaverMapView*)self).onMove(@{
      @"animated": @(animated),
      @"reason": @(reason)
    });
}


- (void)mapViewOptionChanged:(NMFMapView *)mapView {
    int num = [[[NSNumber alloc] initWithInt:mapView.positionMode] intValue];

    if (((RNNaverMapView*)self).onChangeLocationTrackingMode != nil)
        ((RNNaverMapView*)self).onChangeLocationTrackingMode(@{
            @"positionMode"        : @(num),
        });
}

@end
