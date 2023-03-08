package com.github.quadflask.react.navermap;

import android.graphics.PointF;
import com.facebook.react.bridge.*;
import com.facebook.react.uimanager.UIManagerModule;
import com.naver.maps.geometry.LatLng;
import com.naver.maps.map.Projection;

public class RNNaverMapJavaModule extends ReactContextBaseJavaModule {

  public static final String REACT_CLASS = "RNNaverMapView";

  public RNNaverMapJavaModule(ReactApplicationContext context) {
    super(context);
  }

  @Override
  public String getName() {
    return REACT_CLASS;
  }

  @ReactMethod
  public void getPointLatLng(final int tag, ReadableMap coordinate, Promise promise) {
    final ReactApplicationContext context = getReactApplicationContext();
    UIManagerModule uiManager = context.getNativeModule(UIManagerModule.class);
    ReadableMap center = coordinate.getMap("center");
    ReadableMap screen = coordinate.getMap("screen");
    double width = screen.getDouble("width") * 4;
    double height = screen.getDouble("height") * 4;

    final LatLng centerCoord = new LatLng(
        center.hasKey("latitude") ? Double.parseDouble(center.getString("latitude")) : 0.0,
        center.hasKey("longitude") ? Double.parseDouble(center.getString("longitude")) : 0.0
    );

    uiManager.addUIBlock(nativeViewHierarchyManager -> {
      RNNaverMapViewContainer mapView = (RNNaverMapViewContainer) nativeViewHierarchyManager.resolveView(tag);
      RNNaverMapView view = mapView.mapView;
      if (view == null) {
        promise.reject("MapView is null");
        return;
      }

      view.getMapAsync(naverMap -> {
        Projection projection = naverMap.getProjection();
        PointF point = projection.toScreenLocation(centerCoord);

        LatLng topLeftCoord = projection.fromScreenLocation(
            new PointF(point.x - (float) width, point.y - (float) height)
        );

        LatLng topRightCoord = projection.fromScreenLocation(
            new PointF(point.x + (float) width, point.y - (float) height)
        );

        LatLng bottomRightCoord = projection.fromScreenLocation(
            new PointF(point.x + (float) width, point.y + (float) height)
        );

        LatLng bottomLeftCoord = projection.fromScreenLocation(
            new PointF(point.x - (float) width, point.y + (float) height)
        );

        WritableMap screenCoords = new WritableNativeMap();
        if (topLeftCoord != null && topRightCoord != null && bottomRightCoord != null && bottomLeftCoord != null) {
          WritableArray topLeft = new WritableNativeArray();
          WritableArray topRight = new WritableNativeArray();
          WritableArray bottomRight = new WritableNativeArray();
          WritableArray bottomLeft = new WritableNativeArray();

          topLeft.pushDouble(topLeftCoord.latitude);
          topLeft.pushDouble(topLeftCoord.longitude);

          topRight.pushDouble(topRightCoord.latitude);
          topRight.pushDouble(topRightCoord.longitude);

          bottomRight.pushDouble(bottomRightCoord.latitude);
          bottomRight.pushDouble(bottomRightCoord.longitude);

          bottomLeft.pushDouble(bottomLeftCoord.latitude);
          bottomLeft.pushDouble(bottomLeftCoord.longitude);

          screenCoords.putArray("topLeftCoord", topLeft);
          screenCoords.putArray("topRightCoord", topRight);
          screenCoords.putArray("bottomRightCoord", bottomRight);
          screenCoords.putArray("bottomLeftCoord", bottomLeft);
        }

        if (screenCoords != null) {
          promise.resolve(screenCoords);
        } else {
          promise.reject("screenCoords is null");
        }

      });
    });
  }
}
