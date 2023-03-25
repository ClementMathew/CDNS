import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';
import '../components/new_tag_payload.dart';
import '../components/send_http_get.dart';
import '../components/send_http_post.dart';
import '../components/tag_data.dart';

import 'package:location/location.dart';

List<LatLng> tappedPoints = [];
List<LatLng> confirmedPoints = [];
List<Marker> markers = [];
List<CircleMarker> circles = [];
String type = "default";
String range = "200";
final location = Location();
late final MapController mapController = MapController();

class TagProvider with ChangeNotifier {
  void addNewTappedPoint(latlng) {
    tappedPoints.add(latlng);
    markers = tappedPoints.map((latlng) {
      return Marker(
        width: 80,
        height: 80,
        point: latlng,
        builder: (ctx) => GestureDetector(
          onTap: () {
            checkIfAlreadyTagged(latlng);
          },
          child: const Icon(
            Icons.location_on,
            size: 60,
            color: Colors.purple,
          ),
        ),
      );
    }).toList();
    notifyListeners();
  }

  void addConfirmedPoint(latlng) {
    confirmedPoints.add(latlng);
    circles = confirmedPoints.map((latlng) {
      return CircleMarker(
          point: latlng,
          color: const Color.fromARGB(99, 55, 138, 227),
          borderStrokeWidth: 1,
          borderColor: Colors.white,
          useRadiusInMeter: true,
          radius: 1000);
    }).toList();
    notifyListeners();
  }

  void addData(String typeData, String rangeData) {
    type = typeData;
    range = rangeData;
    notifyListeners();
  }

  List<LatLng> get getTappedPoints => tappedPoints;
  List<LatLng> get getConfirmedPoints => confirmedPoints;
  List<Marker> get getMarkers => markers;
  List<CircleMarker> get getCircles => circles;
  MapController get getMapController => mapController;

  void handleTap(TapPosition tapPosition, LatLng latlng) {
    if (checkIfAlreadyTagged(latlng)) {
      addNewTappedPoint(latlng);
      notifyListeners();

      var isSuccess = sendHttpPost(
          lat: latlng.latitude.toString(),
          lon: latlng.longitude.toString(),
          range: range,
          type: type);

      isSuccess.then((value) {
        if (value == "Success") {
          addConfirmedPoint(latlng);
          notifyListeners();
        }
      });
    }
  }

  void getAllMarkers() async {
    try {
      final currentLocation = await location.getLocation();
      mapController.move(
          LatLng(currentLocation.latitude!, currentLocation.longitude!), 14);
      Future<List<Tag>> data = httpGetAllMarkers(
          currentLocation.latitude!, currentLocation.longitude!);
      data.then((value) {
        for (var element in value) {
          LatLng latlng = LatLng(element.lat, element.lng);
          addNewTappedPoint(latlng);
          addConfirmedPoint(latlng);
          notifyListeners();
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }
}

bool checkIfAlreadyTagged(LatLng latLng) {
  var isSuccess = sendHttpGet(
      lat: latLng.latitude.toString(), lng: latLng.longitude.toString());
  //print("Here it is");
  isSuccess.then((value) {
    if (value == "success") {
      print("Success");
      false;
    } else {
      print(value);
    }
  });
  return true;
}
