import 'dart:math';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:js' as js; // Import for JavaScript interop

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LIFE TIME DREAM PROPERTY - 360° Virtual Tour',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _panoId = 0;
  final ScrollController _scrollController = ScrollController();

  // Add state for sensor control and VR mode
  SensorControl _sensorControl = SensorControl.orientation;
  bool _isVRMode = false;
  bool _hasGyroscopePermission = false; // New state for gyroscope permission
  bool _isAppLoading = true; // New state for preloader

  final List<String> imageNames = [
    'Entrance',
    '11',
    '10',
    '5',
    '6',
    '7',
    '8',
    '9',
    '1',
    '2',
    '3',
    'Mountain view',
    'Mountain view from down',
    '4',
  ];

  // Define initial latitude and longitude for each image
  final List<Map<String, double>> initialViews = [
    {'lat': 10.0, 'lon': 10.0},    // Image 0: Entrance
    {'lat': 10.0, 'lon': 20.0},   // Image 1: '11'
    {'lat': 0.0, 'lon': 30.0},    // Image 2: '10'
    {'lat': -5.0, 'lon': -80.0},  // Image 3: '5'
    {'lat': 0.0, 'lon': 50.0},    // Image 4: '6'
    {'lat': -10.0, 'lon': 70.0},  // Image 5: '7'
    {'lat': 0.0, 'lon': 245.0},   // Image 6: '8'
    {'lat': 5.0, 'lon': 330.0},   // Image 7: '9'
    {'lat': 0.0, 'lon': 270.0},   // Image 8: '1'
    {'lat': -5.0, 'lon': 190.0},  // Image 9: '2'
    {'lat': 0.0, 'lon': 60.0},    // Image 10: '3'
    {'lat': 10.0, 'lon': 160.0},  // Image 11: 'Mountain view'
    {'lat': 0.0, 'lon': 95.0},    // Image 12: 'Mountain view from down'
    {'lat': -5.0, 'lon': -180.0}, // Image 13: '4'
  ];

  Map<String, AnimationController> _controllers = {};
  Map<String, Animation<double>> _animations = {};

  // Normalized (0-1) positions for each panorama on the new site map image
  // These are best-guess mappings to the blue pins on the map, adjust as needed for accuracy
  final List<Offset> mapMarkerPositions = [
    Offset(0.5660, 1.0029),
    Offset(0.4613, 1.0182),
    Offset(0.4905, 0.9171),
    Offset(0.4592, 0.8524),
    Offset(0.5293, 0.6855),
    Offset(0.5974, 0.5409),
    Offset(0.5437, 0.4198),
    Offset(0.6207, 0.2904),
    Offset(0.4927, 0.2975),
    Offset(0.4135, 0.4421),
    Offset(0.3540, 0.6091),
    Offset(0.3189, 0.6631),
    Offset(0.3428, 0.7137),
    Offset(0.4119, 0.7490),
  ];

  List<Offset> _editablePositions = [];

  @override
  void initState() {
    super.initState();
    _checkAndRequestDeviceOrientationPermission(); // Call this early
    _scrollToCurrentImage();
    _loadMarkerPositions();
    _editablePositions = List<Offset>.from(mapMarkerPositions);
    // Set a small delay for the preloader to be visible
    Future.delayed(const Duration(milliseconds: 1500), () { // Adjust delay as needed
      if (mounted) {
        setState(() {
          _isAppLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentImage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        double offset = (_panoId * 70.0) - (MediaQuery.of(context).size.width / 2) + 35.0;
        offset = offset.clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadMarkerPositions() async {
    final loaded = await loadMarkerPositions(mapMarkerPositions.length);
    if (loaded != null) {
      setState(() {
        for (int i = 0; i < loaded.length; i++) {
          mapMarkerPositions[i] = loaded[i];
        }
      });
    }
  }

  // Function to check and request Device Orientation permission for iOS
  Future<void> _checkAndRequestDeviceOrientationPermission() async {
    // Check if DeviceOrientationEvent is supported by the browser
    if (!js.context.hasProperty('DeviceOrientationEvent')) {
      setState(() {
        _hasGyroscopePermission = false;
        _sensorControl = SensorControl.none; // Fallback to touch if no support
      });
      print("Device does not support Device Orientation (gyroscope).");
      return;
    }

    // Check for requestPermission for iOS 13+ Safari
    if (js.context['DeviceOrientationEvent'].hasProperty('requestPermission')) {
      try {
        final String? permissionState = await js.context['DeviceOrientationEvent']
            .callMethod('requestPermission') as String?;
        if (permissionState == 'granted') {
          setState(() {
            _hasGyroscopePermission = true;
            _sensorControl = SensorControl.orientation; // Enable gyroscope
          });
          print("Device orientation permission granted.");
        } else {
          setState(() {
            _hasGyroscopePermission = false;
            _sensorControl = SensorControl.none; // Fallback to touch
          });
          print("Device orientation permission denied.");
        }
      } catch (e) {
        setState(() {
          _hasGyroscopePermission = false;
          _sensorControl = SensorControl.none; // Fallback to touch
        });
        print("Error requesting device orientation permission: $e");
      }
    } else {
      // Non-iOS or older iOS, typically permissions are automatic or not required
      setState(() {
        _hasGyroscopePermission = true; // Assume available and granted
        _sensorControl = SensorControl.orientation; // Enable gyroscope by default
      });
      print("Device Orientation Event available (no explicit permission needed).");
    }
  }

  List<List<Hotspot>> get panoHotspots {
    // Define the tripod logo hotspot
    Hotspot tripodLogoHotspot = hotspot(
      longitude: 26.0,
      latitude: -90.0,
      rotation: 0,
      tilt: 0.0,
      scale: 1.0,
      text: "logo-tripod",
      nextId: null,
      style: ArrowStyle(
        imagePath: 'assets/Kodai360/LIFETIMEPROPERTY360.png',
        color: Colors.transparent,
      ),
      animationType: 'none',
      animationDuration: 1,
      number: null,
    );
    int hotspotCounter = 1;
    Hotspot numberedHotspot({
      required double longitude,
      required double latitude,
      required double rotation,
      required double tilt,
      required double scale,
      required String text,
      required int? nextId,
      required ArrowStyle style,
      required String animationType,
      required int animationDuration,
    }) {
      return hotspot(
        longitude: longitude,
        latitude: latitude,
        rotation: rotation,
        tilt: tilt,
        scale: scale,
        text: text,
        nextId: nextId,
        style: style,
        animationType: animationType,
        animationDuration: animationDuration,
        number: hotspotCounter++,
      );
    }
    int commentCounter = 1;
    return [
      // =============================
      // Image 0: Entrance
      // Command: assets/Kodai360/Entrance.jpg
      [
        // Hotspot #1: Go Forward (to image 1: 11)
        numberedHotspot(
          longitude: 10.0,
          latitude: -2.0,
          rotation: -50.0,
          tilt: 0.5,
          scale: 1.0,
          text: "Go Forward",
          nextId: 1,
          style: ArrowStyle( imageUrl:'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #1
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 1: 11
      // Command: assets/Kodai360/11.jpg
      [
        // Hotspot #2: Enter House (to image 2: 10)
        numberedHotspot(
          longitude: 6.0,
          latitude: -17.0,
          rotation: -50,
          tilt: 0.5,
          scale: 1.0,
          text: "Enter House",
          nextId: 2,
          style: ArrowStyle( imageUrl:'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'bounce',
          animationDuration: 1500,
        ), // #2
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 2: 10
      // Command: assets/Kodai360/10.jpg
      [
        // Hotspot #3: Next (to image 3: 5)
        numberedHotspot(
          longitude: 5.0,
          latitude: -15.0,
          rotation: pi / 8,
          tilt: 0.5,
          scale: 1.0,
          text: "Next",
          nextId: 3,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #3
        // Hotspot #4: Back (to image 1: 11)
        numberedHotspot(
          longitude: -97.0,
          latitude: -20.0,
          rotation: -pi / 8,
          tilt: 0.5,
          scale: 1.0,
          text: "Back",
          nextId: 1,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #4
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 3: 5
      // Command: assets/Kodai360/5.jpg
      [
        // Hotspot #5: Return (to image 2: 10)
        numberedHotspot(
          longitude: -81.0,
          latitude: -30.0,
          rotation: -pi / 4,
          tilt: 0.5,
          scale: 1.1,
          text: "Return",
          nextId: 2,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'bounce',
          animationDuration: 1200,
        ), // #5
        // Hotspot #6: Park (to image 4: 6)
        numberedHotspot(
          longitude: -180.0,
          latitude: -15.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "Park",
          nextId: 4,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #6
        // Hotspot #7: Mountain (to image 13: 4)
        numberedHotspot(
          longitude: -260.0,
          latitude: -7.0,
          rotation: -pi / 2,
          tilt: 0.15,
          scale: 1.0,
          text: "Mountain",
          nextId: 13,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #7
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 4: 6
      // Command: assets/Kodai360/6.jpg
      [
        // Hotspot #8: Prev (to image 3: 5)
        numberedHotspot(
          longitude: 50.0,
          latitude: -15.0,
          rotation: pi / 6,
          tilt: 0.6,
          scale: 1.0,
          text: "Prev",
          nextId: 3,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'bounce',
          animationDuration: 1000,
        ), // #8
        // Hotspot #9: Garden (to image 5: 7)
        numberedHotspot(
          longitude: -130.0,
          latitude: -10.0,
          rotation: -pi / 3,
          tilt: 0.4,
          scale: 1.0,
          text: "Garden",
          nextId: 5,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #9
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 5: 7
      // Command: assets/Kodai360/7.jpg
      [
        // Hotspot #10: Back (to image 4: 6)
        numberedHotspot(
          longitude: -65.0,
          latitude: -25.0,
          rotation: pi,
          tilt: 0.5,
          scale: 1.0,
          text: "Back",
          nextId: 4,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #10
        // Hotspot #11: Next (to image 6: 8)
        numberedHotspot(
          longitude: 70.0,
          latitude: -15.0,
          rotation: pi / 5,
          tilt: 0.7,
          scale: 1.1,
          text: "Next",
          nextId: 6,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #11
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 6: 8
      // Command: assets/Kodai360/8.jpg
      [
        // Hotspot #12: Garden (to image 7: 8)
        numberedHotspot(
          longitude: 245.0,
          latitude: -10.0,
          rotation: pi / 2,
          tilt: 0.4,
          scale: 1.0,
          text: "Garden",
          nextId: 7,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'bounce',
          animationDuration: 1200,
        ), // #12
        // Hotspot #13: View (to image 8: 1)
        numberedHotspot(
          longitude: 175.0,
          latitude: -5.0,
          rotation: pi / 3,
          tilt: 0.3,
          scale: 0.9,
          text: "View",
          nextId: 8,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #13
        // Hotspot #14: Return (to image 5: 6)
        numberedHotspot(
          longitude: 352.0,
          latitude: -25.0,
          rotation: pi,
          tilt: 0.5,
          scale: 1.0,
          text: "Return",
          nextId: 5,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #14
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 7: 9
      // Command: assets/Kodai360/9.jpg
      [
        // Hotspot #15: Back (to image 6: 8)
        numberedHotspot(
          longitude: 330.0,
          latitude: -25.0,
          rotation: 3 * pi / 4,
          tilt: 0.5,
          scale: 1.0,
          text: "Back",
          nextId: 6,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'bounce',
          animationDuration: 1000,
        ), // #15
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 8: 1
      // Command: assets/Kodai360/1.jpg
      [
        // Hotspot #16: Explore (to image 1: 11)
        numberedHotspot(
          longitude: 270.0,
          latitude: -15.0,
          rotation: pi / 2,
          tilt: 0.2,
          scale: 1.0,
          text: "Explore",
          nextId: null,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #16
        // Hotspot #17: Park (to image 6: 8)
        numberedHotspot(
          longitude: -7.0,
          latitude: -25.0,
          rotation: 0.0,
          tilt: 0.3,
          scale: 1.0,
          text: "Park",
          nextId: 6,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #17
        // Hotspot #18: View (to image 9: 2)
        numberedHotspot(
          longitude: 60.0,
          latitude: -5.0,
          rotation: pi / 6,
          tilt: 0.8,
          scale: 0.9,
          text: "View",
          nextId: 9,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'bounce',
          animationDuration: 1200,
        ), // #18
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 9: 2
      // Command: assets/Kodai360/2.jpg
      [
        // Hotspot #19: Park (to image 8: 1)
        numberedHotspot(
          longitude: 190.0,
          latitude: -10.0,
          rotation: pi / 2,
          tilt: 0.5,
          scale: 1.0,
          text: "Park",
          nextId: 8,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #19
        // Hotspot #20: Mountain (to image 10: 3)
        numberedHotspot(
          longitude: -355.0,
          latitude: -25.0,
          rotation: -pi,
          tilt: 2.0,
          scale: 0.9,
          text: "Mountain",
          nextId: 10,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #20
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 10: 3
      // Command: assets/Kodai360/3.jpg
      [
        // Hotspot #21: Return (to image 13: 4)
        numberedHotspot(
          longitude: 180.0,
          latitude: -25.0,
          rotation: pi / 4,
          tilt: 0.8,
          scale: 1.0,
          text: "Return",
          nextId: 13,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'bounce',
          animationDuration: 1000,
        ), // #21
        // Hotspot #22: Garden (to image 9: 2)
        numberedHotspot(
          longitude: 60.0,
          latitude: -15.0,
          rotation: pi / 4,
          tilt: 0.6,
          scale: 1.0,
          text: "Garden",
          nextId: 9,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #22
        // Hotspot #23: Down View (to image 12: 3)
        numberedHotspot(
          longitude: 265.0,
          latitude: -5.0,
          rotation: pi / 6,
          tilt: 0.7,
          scale: 0.9,
          text: "Down View",
          nextId: 12,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #23
        // Hotspot #24: Top View (to image 11: 3)
        numberedHotspot(
          longitude: 209.0,
          latitude: -6.0,
          rotation: pi / 3,
          tilt: 0.6,
          scale: 1.0,
          text: "Top View",
          nextId: 11,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'bounce',
          animationDuration: 1200,
        ), // #24
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 11: Mountain view
      // Command: assets/Kodai360/Mountain_view.jpg
      [
        // Hotspot #25: Back (to image 10: 3)
        numberedHotspot(
          longitude: 140.0,
          latitude: -25.0,
          rotation: 3 * pi / 4,
          tilt: 0.5,
          scale: 1.0,
          text: "Back",
          nextId: 10,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #25
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 12: Mountain view from down
      // Command: assets/Kodai360/Mountain_view_from_down.jpg
      [
        // Hotspot #26: Back (to image 10: 3)
        numberedHotspot(
          longitude: 95.0,
          latitude: -15.0,
          rotation: pi / 2,
          tilt: 0.8,
          scale: 1.0,
          text: "Back",
          nextId: 10,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #26
        // Hotspot #27: Back (to image 10: 3)
        numberedHotspot(
          longitude: -85.0,
          latitude: -10.0,
          rotation: -pi / 2,
          tilt: 0.6,
          scale: 1.0,
          text: "Back",
          nextId: 10,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'bounce',
          animationDuration: 1000,
        ), // #27
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 13: 4
      // Command: assets/Kodai360/4.jpg
      [
        // Hotspot #28: Entrance (to image 3: 5)
        numberedHotspot(
          longitude: -180.0,
          latitude: -25.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "Entrance",
          nextId: 3,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #28
        // Hotspot #29: Mountain (to image 10: 3)
        numberedHotspot(
          longitude: -358.0,
          latitude: -5.0,
          rotation: -pi,
          tilt: 0.3,
          scale: 0.9,
          text: "Mountain",
          nextId: 10,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #29
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
    ];
  }

  Hotspot hotspot({
    required double longitude,
    required double latitude,
    required double rotation,
    required double tilt,
    required double scale,
    required String text,
    required int? nextId,
    required ArrowStyle style,
    required String animationType,
    required int animationDuration,
    int? number,
  }) {
    final String hotspotKey = '$longitude-$latitude-$text';
    if (!_controllers.containsKey(hotspotKey)) {
      _controllers[hotspotKey] = AnimationController(
        duration: Duration(milliseconds: animationDuration),
        vsync: this,
      )..repeat(reverse: true);

      switch (animationType) {
        case 'pulse':
          _animations[hotspotKey] = Tween<double>(begin: 1.0, end: 1.05).animate(
            CurvedAnimation(parent: _controllers[hotspotKey]!, curve: Curves.easeInOut),
          );
          break;
        case 'bounce':
          _animations[hotspotKey] = Tween<double>(begin: 0.0, end: -5.0).animate(
            CurvedAnimation(parent: _controllers[hotspotKey]!, curve: Curves.easeInOut),
          );
          break;
        case 'fade':
          _animations[hotspotKey] = Tween<double>(begin: 0.7, end: 1.0).animate(
            CurvedAnimation(parent: _controllers[hotspotKey]!, curve: Curves.easeInOut),
          );
          break;
        case 'none':
          _animations[hotspotKey] = Tween<double>(begin: 1.0, end: 1.0).animate(
            CurvedAnimation(parent: _controllers[hotspotKey]!, curve: Curves.easeInOut),
          );
          break;
        default:
          _animations[hotspotKey] = Tween<double>(begin: 1.0, end: 1.0).animate(
            CurvedAnimation(parent: _controllers[hotspotKey]!, curve: Curves.easeInOut),
          );
      }
    }

    // If this is the logo hotspot, make it much larger
    double hotspotWidth = 80 * scale;
    double hotspotHeight = 80 * scale;
    if (style.imagePath != null && style.imagePath!.contains('LIFETIMEPROPERTY360.png')) {
      hotspotWidth = 700;
      hotspotHeight = 700;
    }

    return Hotspot(
      latitude: latitude,
      longitude: longitude,
      width: hotspotWidth,
      height: hotspotHeight,
      widget: hotspotButton(
        text: text,
        onPressed: () {
          if (nextId != null) {
            setState(() {
              _panoId = nextId;
              _scrollToCurrentImage();
            });
          }
        },
        rotation: rotation,
        tilt: tilt,
        scale: scale,
        style: style,
        animationType: animationType,
        animation: _animations[hotspotKey]!,
        number: number,
      ),
    );
  }

  Widget hotspotButton({
    required String text,
    required VoidCallback onPressed,
    required double rotation,
    required double tilt,
    required double scale,
    required ArrowStyle style,
    required String animationType,
    required Animation<double> animation,
    int? number,
  }) {
    final bool isLogo = style.imagePath != null && style.imagePath!.contains('LIFETIMEPROPERTY360.png');
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => GestureDetector(
        onTap: onPressed,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Only show the black shadow/overlay for non-logo hotspots
            if (!isLogo)
              Positioned(
                left: 5,
                top: 5,
                child: Opacity(
                  opacity: 0.3,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateX(tilt)
                      ..rotateZ(rotation)
                      ..scale(scale),
                    child: Image(
                      image: getArrowImageProvider(style),
                      width: 80 * scale,
                      height: 80 * scale,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateX(tilt)
                ..rotateZ(rotation)
                ..scale(scale),
              child: _buildAnimatedArrow(
                animationType: animationType,
                animation: animation,
                style: style,
                scale: scale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedArrow({
    required String animationType,
    required Animation<double> animation,
    required ArrowStyle style,
    required double scale,
  }) {
    double finalSize = 120 * scale;
    Widget image = buildArrowImage(style, finalSize, finalSize);
    switch (animationType) {
      case 'pulse':
        return Transform.scale(scale: animation.value, child: image);
      case 'bounce':
        return Transform.translate(offset: Offset(0, animation.value), child: image);
      case 'fade':
        return Opacity(opacity: animation.value, child: image);
      case 'none':
        return image;
      default:
        return image;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAppLoading) {
      return Container(
        color: Colors.black, // You can choose any background color
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/Kodai360/LIFETIMEPROPERTY360.png',
                width: 150, // Adjust size as needed
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Loading Virtual Tour...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    Widget panoramaWidget = PanoramaViewer(
      key: ValueKey(_panoId.toString() + _sensorControl.toString()),
      animSpeed: 1.0,
      sensorControl: _sensorControl,
      latitude: initialViews[_panoId]['lat']!,
      longitude: initialViews[_panoId]['lon']!,
      hotspots: panoHotspots[_panoId % imageNames.length],
      child: Image.asset('assets/Kodai360/${imageNames[_panoId % imageNames.length]}.jpg'),
    );

    // VR mode: show two panoramas side by side with slightly offset longitude
    Widget vrWidget = Row(
      children: [
        Expanded(
          child: PanoramaViewer(
            key: ValueKey('vr_left_$_panoId'),
            animSpeed: 1.0,
            sensorControl: _sensorControl,
            latitude: initialViews[_panoId]['lat']!,
            longitude: (initialViews[_panoId]['lon']! - 5),
            hotspots: panoHotspots[_panoId % imageNames.length],
            child: Image.asset('assets/Kodai360/${imageNames[_panoId % imageNames.length]}.jpg'),
          ),
        ),
        Expanded(
          child: PanoramaViewer(
            key: ValueKey('vr_right_$_panoId'),
            animSpeed: 1.0,
            sensorControl: _sensorControl,
            latitude: initialViews[_panoId]['lat']!,
            longitude: (initialViews[_panoId]['lon']! + 5),
            hotspots: panoHotspots[_panoId % imageNames.length],
            child: Image.asset('assets/Kodai360/${imageNames[_panoId % imageNames.length]}.jpg'),
          ),
        ),
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          _isVRMode ? vrWidget : panoramaWidget,
          _buildTopLeftLogoAndText(),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(imageNames.length, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _panoId = index;
                                _scrollToCurrentImage();
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _panoId == index ? Colors.white : Colors.grey,
                                  width: _panoId == index ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/Kodai360/${imageNames[index]}.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        _scrollController.animateTo(
                          _scrollController.offset - 100,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 8,
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onPressed: () {
                        _scrollController.animateTo(
                          _scrollController.offset + 100,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating map toggle button (place inside Stack)
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Map toggle button - show only if screen size is sufficient
                Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final screenHeight = MediaQuery.of(context).size.height;
                    if (screenWidth >= 659 && screenHeight >= 647) {
                      return FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.map, color: Colors.black),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => _MapOverlayDialog(
                              imageNames: imageNames,
                              mapMarkerPositions: mapMarkerPositions,
                              currentId: _panoId,
                              onJumpToPanorama: (index) {
                                setState(() {
                                  _panoId = index;
                                  _scrollToCurrentImage();
                                });
                              },
                            ),
                          );
                        },
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Gyroscope/touch toggle button
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  child: Icon(
                    _sensorControl == SensorControl.orientation
                        ? Icons.screen_rotation
                        : Icons.pan_tool,
                    color: Colors.black,
                  ),
                  tooltip: _sensorControl == SensorControl.orientation
                      ? 'Gyroscope ON (Tap to use Touch)'
                      : 'Touch ON (Tap to use Gyroscope)',
                  onPressed: () {
                    // Only allow toggling if gyroscope is supported and permission is granted
                    if (_hasGyroscopePermission) {
                      setState(() {
                        _sensorControl = _sensorControl == SensorControl.orientation
                            ? SensorControl.none
                            : SensorControl.orientation;
                      });
                    } else {
                      // If gyroscope is not available or permission denied, try to request again
                      _checkAndRequestDeviceOrientationPermission();
                    }
                  },
                ),
                const SizedBox(height: 12),
                // VR mode toggle button
                FloatingActionButton(
                  mini: true,
                  backgroundColor: _isVRMode ? Colors.blue : Colors.white,
                  child: Icon(Icons.vrpano, color: _isVRMode ? Colors.white : Colors.black),
                  tooltip: _isVRMode ? 'Exit VR Mode' : 'Enter VR Mode',
                  onPressed: () {
                    setState(() {
                      _isVRMode = !_isVRMode;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New method to build the logo and text
  Widget _buildTopLeftLogoAndText() {
    return Positioned(
      top: 10,
      left: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/Kodai360/LOGO.png',
            width: 60, // Adjust size as needed
            height: 60, // Adjust size as needed
          ),
          const SizedBox(width: 8),
          const Text(
            'KODAI HIGHLAND CREEK',
            style: TextStyle(
              fontFamily: 'MuaraRough',
              fontSize: 24,
              color: Color(0xFF044f88), // Blue color from the image
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ArrowStyle {
  final String? imagePath;
  final String? imageUrl;
  final Color color;

  ArrowStyle({this.imagePath, this.imageUrl, required this.color});
}

Widget buildArrowImage(ArrowStyle style, double width, double height) {
  if (style.imagePath != null && style.imagePath!.contains('LIFETIMEPROPERTY360.png')) {
    // Make the logo extremely large to cover the tripod
    return Center(
      child: SizedBox(
        width: 6000, // Even larger for maximum coverage
        height: 6000,
        child: Image.asset(
          style.imagePath!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
  if (style.imageUrl != null) {
    return Image.network(
      style.imageUrl!,
      width: width,
      height: height,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
        print('Error loading network image ${style.imageUrl}: $error');
        return Container(
          width: width,
          height: height,
          color: Colors.grey,
          child: Center(child: Text('Net Err', style: TextStyle(color: Colors.red, fontSize: 10))),
        );
      },
    );
  } else {
    if (style.imagePath == null) {
      print("Error: ArrowStyle has no imagePath for local asset.");
      return Container(
        width: width,
        height: height,
        color: Colors.red,
        child: Center(child: Text("No Path!", style: TextStyle(color: Colors.white, fontSize: 10))),
      );
    }
    return ClipOval(
      child: Image.asset(
        style.imagePath!,
        width: width,
        height: height,
        fit: BoxFit.contain,
        color: style.color == Colors.transparent ? null : style.color,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          print('Error loading asset ${style.imagePath}: $error');
          return Container(
            width: width,
            height: height,
            color: Colors.grey,
            child: Center(child: Text('Asset Err', style: TextStyle(color: Colors.red, fontSize: 10))),
          );
        },
      ),
    );
  }
}

ImageProvider getArrowImageProvider(ArrowStyle style) {
  if (style.imageUrl != null) {
    return CachedNetworkImageProvider(style.imageUrl!);
  } else {
    return AssetImage(style.imagePath!);
  }
}

// Modern Map Overlay Dialog with Fullscreen and Tooltips
class _MapOverlayDialog extends StatefulWidget {
  final List<String> imageNames;
  final List<Offset> mapMarkerPositions;
  final int currentId;
  final void Function(int) onJumpToPanorama;
  const _MapOverlayDialog({
    required this.imageNames,
    required this.mapMarkerPositions,
    required this.currentId,
    required this.onJumpToPanorama,
    super.key,
  });
  @override
  State<_MapOverlayDialog> createState() => _MapOverlayDialogState();
}

class _MapOverlayDialogState extends State<_MapOverlayDialog> {
  bool _fullscreen = false;
  List<Offset> _editablePositions = [];

  @override
  void initState() {
    super.initState();
    _editablePositions = List<Offset>.from(widget.mapMarkerPositions);
  }

  @override
  Widget build(BuildContext context) {
    final double mapWidth = _fullscreen ? MediaQuery.of(context).size.width * 0.98 : 600;
    final double mapHeight = _fullscreen ? MediaQuery.of(context).size.height * 0.90 : 400;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: _fullscreen ? 0 : 24, vertical: _fullscreen ? 0 : 24),
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            width: mapWidth,
            height: mapHeight,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 24)],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'assets/MRF/MMIP_Map.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Markers
                ...List.generate(widget.imageNames.length, (index) {
                  final Offset pos = _editablePositions[index];
                  final bool isCurrent = widget.currentId == index;
                  return Positioned(
                    left: pos.dx * mapWidth - 20,
                    top: pos.dy * mapHeight - 40,
                    child: Tooltip(
                      message: widget.imageNames[index],
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onJumpToPanorama(index);
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCurrent ? Colors.orangeAccent : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCurrent ? Colors.deepOrange : Colors.black,
                              width: isCurrent ? 4 : 2,
                            ),
                            boxShadow: isCurrent
                                ? [BoxShadow(color: Colors.orange.withOpacity(0.7), blurRadius: 12)]
                                : [],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.location_on,
                              color: isCurrent ? Colors.white : Colors.deepOrange,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // Fullscreen toggle button
                Positioned(
                  top: 16,
                  right: 60,
                  child: IconButton(
                    icon: Icon(_fullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.black, size: 32),
                    tooltip: _fullscreen ? 'Exit Fullscreen' : 'Fullscreen',
                    onPressed: () {
                      setState(() => _fullscreen = !_fullscreen);
                    },
                  ),
                ),
                // Close button
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.black, size: 32),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Place these at the top-level, outside any class
Future<void> saveMarkerPositions(List<Offset> positions) async {
  final prefs = await SharedPreferences.getInstance();
  final List<String> toSave = positions.map((e) => "${e.dx},${e.dy}").toList();
  await prefs.setStringList('marker_positions', toSave);
}

Future<List<Offset>?> loadMarkerPositions(int count) async {
  final prefs = await SharedPreferences.getInstance();
  final List<String>? saved = prefs.getStringList('marker_positions');
  if (saved != null && saved.length == count) {
    return saved.map((s) {
      final parts = s.split(',');
      return Offset(double.parse(parts[0]), double.parse(parts[1]));
    }).toList();
  }
  return null;
}