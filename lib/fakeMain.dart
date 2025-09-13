//import 'dart:ffi';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:js' as js;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MCC MRF Innovation Park - 360° Virtual Tour',
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
  bool isvisble = true;
  final ScrollController _scrollController = ScrollController();

  SensorControl _sensorControl = SensorControl.orientation;
  bool _isVRMode = false;
  bool _isAutoViewer = false;
  double _isviewerSpeed = 0.0;
  bool _hasGyroscopePermission = false;
  bool _isAppLoading = true;
  double _vrIPD = 65.0;

  // Optimized animation handling
  late AnimationController _sharedAnimationController;
  final Map<String, Animation<double>> _animations = {};
  final Map<String, String> _hotspotAnimationTypes = {};

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return IconButton(
      color: isActive ? Colors.blueAccent : Colors.white,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
    );
  }

  // Static data to reduce memory allocations
  static const List<String> _imageNames = [
    'enterence', 'enterence2', 'innovation_parlc', 'zebra1', 'unicornMeet',
    'center_bus', 'mini_con', 'statupmeet', 'researchroom', 'ground_lift',
    'lab1', 'lab2', 'lab3', 'lab4', 'lab5', 'lab6', 'lab7', 'lab8',
    'ground_staircase', 'cafe2', 'Cafe1', 'fub_enterence', 'fab_1', 'fub2',
    'fub3', 'thinking_space', 'firstFoolr_staircase', 'camel1', 'hubroom_gf',
    'hubroom_ff', 'computional_info', 'firstFloor', 'psycholgy', 'dataScience',
    'pentagon1', 'pentagon_outdoor', 'groundFloor', 'paneePlane', 'centerOfNano',
    'outdoor1', 'outdoor2', 'outdoor3', 'blueWhaleroom',
  ];

  static const List<String> _placeNames = [
    'Enterance', 'Path to Parlc', 'Innovation Parlc', 'Zebra Room', 'Camel Room',
    'Center of Business', 'Mini Conference Room', 'Unicorn (Meet)Room', 'researchroom',
    'Ground Floor Lift', 'lab1', 'lab2', 'lab3', 'lab4', 'lab5', 'lab6', 'lab7',
    'lab8', 'Ground StairCase', 'Cafe Hall', 'Cafe', 'Fab_enterence', 'Fab 1',
    'Fab 2', 'Fab 3', 'Thinking Space', 'FirstFloor StairCase', 'First Floor Path',
    'Hub Room GF', 'Hub Room FF', 'Computional Lab', 'First Floor', 'Psychology Lab',
    'Data Science Lab', 'Pentagon Innovations', 'Pentagon Outdoor', 'Ground Floor',
    'PaneePlane Room ', 'centerOfNano', 'Outdoor 1', 'Outdoor 2', 'Outdoor 3',
    'BlueWhale Room',
  ];

  static const List<Map<String, double>> _initialViews = [
    {'lat': -6.0, 'lon': -145.0}, {'lat': 4.0, 'lon': -145.0}, {'lat': 3.0, 'lon': 110.0},
    {'lat': -5.0, 'lon': 10.0}, {'lat': 0.0, 'lon': 0.0}, {'lat': -10.0, 'lon': -100.0},
    {'lat': 0.0, 'lon': 175}, {'lat': 5.0, 'lon': 358}, {'lat': 0.0, 'lon': -175},
    {'lat': -5.0, 'lon': 150}, {'lat': 0.5, 'lon': 100}, {'lat': -10, 'lon': -60},
    {'lat': 0.0, 'lon': -70}, {'lat': -5.0, 'lon': 105}, {'lat': -5.0, 'lon': -85.0},
    {'lat': -5.0, 'lon': -180.0}, {'lat': -5.0, 'lon': -345.0}, {'lat': -5.0, 'lon': -180.0},
    {'lat': -5.0, 'lon': -170.0}, {'lat': -5.0, 'lon': -180.0}, {'lat': -5.0, 'lon': -85.0},
    {'lat': 5.0, 'lon': -360.0}, {'lat': -5.0, 'lon': -360.0}, {'lat': -5.0, 'lon': -180.0},
    {'lat': -5.0, 'lon': -180.0}, {'lat': -5.0, 'lon': -195.0}, {'lat': -5.0, 'lon': -360.0},
    {'lat': -5.0, 'lon': -180.0}, {'lat': -3.0, 'lon': -355.0}, {'lat': -3.0, 'lon': -90.0},
    {'lat': -3.0, 'lon': -80.0}, {'lat': -3.0, 'lon': -100.0}, {'lat': -5.0, 'lon': -240.0},
    {'lat': -3.0, 'lon': -110.0}, {'lat': -5.0, 'lon': -260.0}, {'lat': -3.0, 'lon': -35.0},
    {'lat': -5.0, 'lon': -295.0}, {'lat': -5.0, 'lon': -180.0}, {'lat': -5.0, 'lon': -350.0},
    {'lat': -3.0, 'lon': -270.0}, {'lat': -3.0, 'lon':  15.0}, {'lat': -2.0, 'lon': -160.0},
    {'lat': -2.0, 'lon': -270.0},
  ];

  static const List<Offset> _mapMarkerPositions = [
    Offset(0.5400, 0.5000), Offset(0.4613, 1.0182), Offset(0.4905, 0.9171),
    Offset(0.4592, 0.8524), Offset(0.5293, 0.6855), Offset(0.5974, 0.5409),
    Offset(0.5437, 0.4198), Offset(0.6207, 0.2904), Offset(0.4927, 0.2975),
    Offset(0.4135, 0.4421), Offset(0.3540, 0.6091), Offset(0.3189, 0.6631),
    Offset(0.3428, 0.7137), Offset(0.3428, 0.7137), Offset(0.3428, 0.7137),
    Offset(0.3428, 0.7137), Offset(0.3428, 0.7137), Offset(0.3428, 0.7137),
    Offset(0.3428, 0.7137), Offset(0.3428, 0.7137), Offset(0.3428, 0.7137),
    Offset(0.3428, 0.7137), Offset(0.3428, 0.7137), Offset(0.3428, 0.7137),
    Offset(0.3428, 0.7137), Offset(0.3428, 0.7137), Offset(0.3428, 0.7137),
    Offset(0.3428, 0.7137), Offset(0.3428, 0.7137), Offset(0.3428, 0.7137),
    Offset(0.3428, 0.7137), Offset(0.3428, 0.7137), Offset(0.3428, 0.7137),
    Offset(0.3428, 0.7137), Offset(0.3428, 0.7137), Offset(0.3428, 0.7137),
    Offset(0.3428, 0.7137), Offset(0.3428, 0.7137), Offset(0.3428, 0.7137),
    Offset(0.3428, 0.7137), Offset(0.3428, 0.7137), Offset(0.3428, 0.7137),
    Offset(0.3428, 0.7137),
  ];

  List<Offset> _editablePositions = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAndRequestDeviceOrientationPermission();
    _scrollToCurrentImage();
    _loadMarkerPositions();
    _editablePositions = List<Offset>.from(_mapMarkerPositions);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isAppLoading = false;
        });
      }
    });
  }

  void _initializeAnimations() {
    _sharedAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sharedAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentImage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        const double imageWidth = 130.0;
        const double imageMargin = 12.0;
        const double totalImageWidth = imageWidth + imageMargin;

        final double screenWidth = MediaQuery.of(context).size.width;
        final double containerWidth = screenWidth - 140;

        double targetOffset = (_panoId * totalImageWidth) - (containerWidth / 2) + (imageWidth / 2);
        targetOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadMarkerPositions() async {
    final loaded = await loadMarkerPositions(_mapMarkerPositions.length);
    if (loaded != null && mounted) {
      setState(() {
        for (int i = 0; i < loaded.length; i++) {
          _editablePositions[i] = loaded[i];
        }
      });
    }
  }

  Future<void> _checkAndRequestDeviceOrientationPermission() async {
    if (!js.context.hasProperty('DeviceOrientationEvent')) {
      if (mounted) {
        setState(() {
          _hasGyroscopePermission = false;
          _sensorControl = SensorControl.none;
        });
      }
      return;
    }

    if (js.context['DeviceOrientationEvent'].hasProperty('requestPermission')) {
      try {
        final String? permissionState = await js.context['DeviceOrientationEvent']
            .callMethod('requestPermission') as String?;
        if (mounted) {
          setState(() {
            _hasGyroscopePermission = permissionState == 'granted';
            _sensorControl = _hasGyroscopePermission ? SensorControl.orientation : SensorControl.none;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasGyroscopePermission = false;
            _sensorControl = SensorControl.none;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _hasGyroscopePermission = true;
          _sensorControl = SensorControl.orientation;
        });
      }
    }
  }

  // Optimized hotspot generation using shared animation controller
  List<List<Hotspot>> get panoHotspots {
    final tripodLogoHotspot = _createTripodHotspot();

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
      return _createOptimizedHotspot(
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

    // All 43 panorama hotspot definitions preserved exactly as original
    return [
      // Image 0: Entrance
      [
        numberedHotspot(
          longitude: -180.0, latitude: -12.0, rotation: -50.1, tilt: 0.8, scale: 1.0,
          text: "Go Forward", nextId: 1,
          style: ArrowStyle(imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white),
          animationType: 'pulse', animationDuration: 1500,
        ),
        tripodLogoHotspot,
      ],

      // Image 1: enterance2
      [
        numberedHotspot(
          longitude: -138.0, latitude: 2.0, rotation: 0, tilt: 0, scale: 1.0,
          text: "Enter enterance2", nextId: 2,
          style: ArrowStyle(imagePath: 'assets/MRF/door.gif', color: Colors.white),
          animationType: 'bounce', animationDuration: 1500,
        ),
        numberedHotspot(
          longitude: 16.0, latitude: -17.0, rotation: -50.2, tilt: 0.4, scale: 1.0,
          text: "back to enterance", nextId: 0,
          style: ArrowStyle(imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white),
          animationType: 'bounce', animationDuration: 1500,
        ),
        tripodLogoHotspot,
      ],

      // Image 2: parlv
      [
        numberedHotspot(
          longitude: 132.0, latitude: 0, rotation: 0, tilt: 0, scale: 1.0,
          text: "Next to center of bus", nextId: 5,
          style: ArrowStyle(imagePath: 'assets/MRF/door.gif', color: Colors.white),
          animationType: 'pulse', animationDuration: 1500,
        ),
        numberedHotspot(
          longitude: 98.0, latitude: 0, rotation: 0, tilt: 0, scale: 1.0,
          text: "Next to camel", nextId: 4,
          style: ArrowStyle(imagePath: 'assets/MRF/door.gif', color: Colors.white),
          animationType: 'pulse', animationDuration: 1500,
        ),
        numberedHotspot(
          longitude: -75.0, latitude: -0.0, rotation: 0, tilt: 0, scale: 1.0,
          text: "Back to enterance2 ", nextId: 1,
          style: ArrowStyle(imagePath: 'assets/MRF/door.gif', color: Colors.white),
          animationType: 'fade', animationDuration: 2000,
        ),
        numberedHotspot(
          longitude: 83.0, latitude: 0, rotation: 0, tilt: 0, scale: 1.0,
          text: "next zebra ", nextId: 3,
          style: ArrowStyle(imagePath: 'assets/MRF/door.gif', color: Colors.white),
          animationType: 'fade', animationDuration: 2000,
        ),
        tripodLogoHotspot,
      ],

      // Image 3: zebra
      [
        numberedHotspot(
          longitude: -193.0, latitude: -17.0, rotation: 0, tilt: 0, scale: 1,
          text: "Return to parlc", nextId: 2,
          style: ArrowStyle(imagePath: 'assets/MRF/door.gif', color: Colors.white),
          animationType: 'bounce', animationDuration: 1200,
        ),
        tripodLogoHotspot,
      ],

      // Image 4: camel
      [
        numberedHotspot(
          longitude: 208.0, latitude: -18.0, rotation: 0, tilt: 0, scale: 1,
          text: "back to Parlc", nextId: 2,
          style: ArrowStyle(imagePath: 'assets/MRF/door.gif', color: Colors.white),
          animationType: 'bounce', animationDuration: 1000,
        ),
        tripodLogoHotspot,
      ],

      // Image 5: center of bus
      [
        numberedHotspot(
          longitude: -68.0, latitude: .0, rotation: 0, tilt: 0, scale: 1.0,
          text: "mini conference", nextId: 6,
          style: ArrowStyle(imagePath: 'assets/MRF/door.gif', color: Colors.white),
          animationType: 'fade', animationDuration: 2000,
        ),
        numberedHotspot(
          longitude: 250.0, latitude: -20.0, rotation: 0, tilt: 0, scale: 1,
          text: "ground Floor lift", nextId: 9,
          style: ArrowStyle(imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white),
          animationType: 'pulse', animationDuration: 1500,
        ),
        numberedHotspot(
          longitude: 150.0, latitude: 1.0, rotation: 0, tilt: 0, scale: 1,
          text: "back to perlc", nextId: 2,
          style: ArrowStyle(imagePath: 'assets/MRF/door.gif', color: Colors.white),
          animationType: 'pulse', animationDuration: 1500,
        ),
        numberedHotspot(
          longitude: 120.0, latitude: 0, rotation: 0, tilt: 0, scale: 1,
          text: "go to unicorn", nextId: 7,
          style: ArrowStyle(imagePath: 'assets/MRF/door.gif', color: Colors.white),
          animationType: 'pulse', animationDuration: 1500,
        ),
        numberedHotspot(
          longitude: 720.0, latitude: 0.0, rotation: 0, tilt: 0, scale: 1,
          text: "research room", nextId: 8,
          style: ArrowStyle(imagePath: 'assets/MRF/door.gif', color: Colors.white),
          animationType: 'pulse', animationDuration: 1500,
        ),
        tripodLogoHotspot,
      ],

      // Continue with remaining panoramas (6-42) - all hotspots preserved
      // Image 6: mini conference
      [
        numberedHotspot(
          longitude: -695.0, latitude: -10.0, rotation: 0, tilt: 0, scale: 1.0,
          text: "back to center of bus", nextId: 5,
          style: ArrowStyle(imagePath: 'assets/MRF/door.gif', color: Colors.white),
          animationType: 'bounce', animationDuration: 1200,
        ),
        tripodLogoHotspot,
      ],

      // Image 7: unicorn (startup meet)
      [
        // Hotspot #1
        numberedHotspot(
          longitude: 331.0,
          latitude: -3.0,
          rotation : 0,
          tilt: 0,
          scale: 1.0,
          text: "Back to center of bus",
          nextId: 5,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'bounce',
          animationDuration: 1000,
        ), // #15
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 8: research room
      [
        // Hotspot #1
        numberedHotspot(
          longitude: -30.0,
          latitude: -3.0,
          rotation: 0,
          tilt: 0,
          scale: 1.0,
          text: "back to center of bus",
          nextId: 5,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 9: ground floor lift
      [
        // Hotspot #1
        numberedHotspot(
          longitude: 0,
          latitude: -10.0,
          rotation: pi / 2,
          tilt: 0.5,
          scale: 1.0,
          text: "go to first floor ",
          nextId: 26,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), //
        // Hotspot #2
        numberedHotspot(
          longitude: -60.0,
          latitude: -25.0,
          rotation: -pi,
          tilt: 2.0,
          scale: 1.1,
          text: "back to center of bus",
          nextId: 5,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: 80,
          latitude: -25.0,
          rotation: -pi,
          tilt: 2.0,
          scale: 1,
          text: "cafe path",
          nextId: 18,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: 148.0,
          latitude: -3.0,
          rotation: 0,
          tilt: 0.0,
          scale: 1,
          text: "enter lab",
          nextId: 10,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 10: lab1

      [
        // Hotspot #1
        numberedHotspot(
          longitude: -40,
          latitude: -5.0,
          rotation: 0,
          tilt: 0,
          scale: 1,
          text: "Return to ground floor lift",
          nextId: 9,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'bounce',
          animationDuration: 1000,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 90,
          latitude: -2.0,
          rotation:  0,
          tilt: 0,
          scale: 1.0,
          text: "go to lab2 ",
          nextId: 11,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -193,
          latitude: -1.0,
          rotation: 0,
          tilt: 0,
          scale: 1,
          text: "go to lab5",
          nextId: 14,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: 135,
          latitude: -2.0,
          rotation:  0,
          tilt: 0,
          scale: 1,
          text: "go to lab8",
          nextId: 17,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'bounce',
          animationDuration: 1200,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 11: Lab2
      [
        // Hotspot #1
        numberedHotspot(
          longitude: 75,
          latitude: -6.0,
          rotation: 0,
          tilt: 0,
          scale: 1.0,
          text: "Back to lab1",
          nextId: 10,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: -62,
          latitude: -8.5,
          rotation:  0,
          tilt: 0,
          scale: 1.0,
          text: "go to lab3",
          nextId: 12,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -22.8,
          latitude: -6,
          rotation: 0,
          tilt: 0,
          scale: 1.0,
          text: "go to lab4",
          nextId: 13,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 12: lab3
      [
        // Hotspot #1
        numberedHotspot(
          longitude: 100.0,
          latitude: -5.0,
          rotation: 0,
          tilt: 0.1,
          scale: 1.0,
          text: "Back to lab 2",
          nextId: 11,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================

      [ // #iamge 13:lab4
        // Hotspot #1
        numberedHotspot(
          longitude: -36,
          latitude: -7,
          rotation: 0.0,
          tilt: 0.3,
          scale: 1.0,
          text: "back to lab2",
          nextId: 11,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [ // #iamge 14 :lab5
        // Hotspot #1
        numberedHotspot(
          longitude: 07,
          latitude: -5.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "back to lab 1",
          nextId: 10,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 130.0,
          latitude: -9.0,
          rotation: 0,
          tilt: 0,
          scale: 1,
          text: "go to lab6",
          nextId: 15,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [ // #iamge 15 lab6
        // Hotspot #1
        numberedHotspot(
          longitude: -140.0,
          latitude: -5,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "go to lab7",
          nextId: 16,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: -22,
          latitude: -5,
          rotation: 0,
          tilt: 0,
          scale: 1,
          text: "back to lab5",
          nextId: 14,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [ // #iamge 16 lab7
        // Hotspot # 1
        numberedHotspot(
          longitude: -138.0,
          latitude: -5,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "back to lab6",
          nextId: 15,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [ // #iamge 17 :lab8
        // Hotspot #1
        numberedHotspot(
          longitude: -175.0,
          latitude: -5,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "back to lab1",
          nextId: 10,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: -50,
          latitude: -18.0,
          rotation: 0,
          tilt: 0,
          scale: 1,
          text: "go to lab2",
          nextId: 11,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [ // #iamge 18 :ground floor
        // Hotspot #1
        numberedHotspot(
          longitude: 10,
          latitude: -25.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "back to ground floor lift",
          nextId: 9,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #28
        // Hotspot #2
        numberedHotspot(
          longitude: -165,
          latitude: -7.3,
          rotation: 0,
          tilt: 1,
          scale: 1,
          text: "go to cafe",
          nextId: 19,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -170,
          latitude: 2.0,
          rotation: 0,
          tilt: 0.4,
          scale: 0.8,
          text: "first floor stair",
          nextId: 31,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: -170,
          latitude: -4.0,
          rotation: pi/2,
          tilt: 0.4,
          scale: 0.8,
          text: "go to ground floor side",
          nextId: 36,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [ // #iamge 19 : cafe
        // Hotspot #1
        numberedHotspot(
          longitude: -180.0,
          latitude: -25.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "go inside cafe",
          nextId: 20,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #28
        // Hotspot #2
        numberedHotspot(
          longitude: -360.0,
          latitude: -1.0,
          rotation: 0,
          tilt: 0.3,
          scale: 0.9,
          text: "go to outside cafe",
          nextId: 18,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -125.0,
          latitude:-2.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "go outdoor1",
          nextId: 39,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: -275.0,
          latitude: -2.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "go inside cafe",
          nextId: 36,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [ //image 20 cafe 2
        // Hotspot #1
        numberedHotspot(
          longitude: 80.0,
          latitude: -5.0,
          rotation: 0.0,
          tilt: 1,
          scale: 1.0,
          text: "back to hall",
          nextId: 19,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 17,
          latitude: -5.0,
          rotation: 0,
          tilt: 0.3,
          scale: 0.9,
          text: "go to fab enterance",
          nextId: 21,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -20,
          latitude: -1.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to think hub",
          nextId: 25,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 21 fab enterane
        // Hotspot #1
        numberedHotspot(
          longitude: 0,
          latitude: -5.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "go to fab1",
          nextId: 22,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: -180,
          latitude: -35.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "back to cafe",
          nextId: 20,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #29
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 22 fab1
        // Hotspot #1
        numberedHotspot(
          longitude: -10,
          latitude: 0.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "go to fab2",
          nextId: 23,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 200,
          latitude: -25,
          rotation: pi/2,
          tilt: 0,
          scale: 1,
          text: "go to enterence",
          nextId: 21,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -340.0,
          latitude: 0.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to fab3",
          nextId: 24,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 23 fab2
        // Hotspot #28: Entrance (to image 3: 5)
        numberedHotspot(
          longitude: 18.0,
          latitude: -10.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "back to fab1",
          nextId: 22,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 24 fab3
        // Hotspot #29: Mountain (to image 10: 3)
        numberedHotspot(
          longitude: -300.0,
          latitude: -5.0,
          rotation: 0,
          tilt: 0,
          scale: 1,
          text: "back to fab1",
          nextId: 22,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #29
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 25 thinking space
        // Hotspot #28: Entrance (to image 3: 5)
        numberedHotspot(
          longitude: -10.0,
          latitude: 5,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "back to cafe",
          nextId: 20,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 26 first floor
        // Hotspot #1
        numberedHotspot(
          longitude: -100,
          latitude: -25.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "back to ground ground floor  lift",
          nextId: 9,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: -20,
          latitude: -1,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to hub",
          nextId: 28,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -35,
          latitude: -10.0,
          rotation: -pi/2,
          tilt:0,
          scale: 0.9,
          text: "first floor path",
          nextId: 27,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: 37.0,
          latitude: -2.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to psycology",
          nextId: 32,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #5
        numberedHotspot(
          longitude: 13,
          latitude: -1,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to hub",
          nextId: 38,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 27 first floor path
        // Hotspot #1
        numberedHotspot(
          longitude: -175.0,
          latitude: -11.0,
          rotation: 50,
          tilt: 0.9,
          scale: 1.0,
          text: "go compution lab ",
          nextId: 30,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: -358.0,
          latitude: -15.0,
          rotation: 0,
          tilt: 0.3,
          scale: 0.9,
          text: "back to first floor stairs",
          nextId: 26,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: 180,
          latitude: -2.0,
          rotation: pi/2,
          tilt: 0,
          scale: 0.7,
          text: "go to first floor side",
          nextId: 31,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 28 hub1
        // Hotspot #28: Entrance (to image 3: 5)
        numberedHotspot(
          longitude: 110,
          latitude: -3,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "go outside",
          nextId: 26,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #29: Mountain (to image 10: 3)
        numberedHotspot(
          longitude: 80,
          latitude: -10.0,
          rotation: -pi/2,
          tilt: 0,
          scale: 0.9,
          text: "go up floor",
          nextId: 29,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #29
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 29 hub2
        // Hotspot #28: Entrance (to image 3: 5)
        numberedHotspot(
          longitude: 50,
          latitude: -20.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "go down floor",
          nextId: 28,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 30 computional lab
        // Hotspot #1
        numberedHotspot(
          longitude: 78.0,
          latitude: -2.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "first floor path",
          nextId: 27,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 213,
          latitude: -2.0,
          rotation: 0,
          tilt: 0.3,
          scale: 0.9,
          text: "go to first floor side",
          nextId: 31,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 31 first floor side
        // Hotspot #1
        numberedHotspot(
          longitude: -110.0,
          latitude: -10.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "back to first floor path",
          nextId: 27,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: -55,
          latitude: -13.0,
          rotation: 0,
          tilt: 0.5,
          scale: 0.9,
          text: "back to ground floor path",
          nextId: 18,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -265.0,
          latitude: 8.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to pentagon",
          nextId: 34,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: -200,
          latitude: -2.0,
          rotation: 0,
          tilt: 0.3,
          scale: 0.9,
          text: "go to computional lab",
          nextId: 30,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #5
        numberedHotspot(
          longitude: -310,
          latitude: -2.0,
          rotation: 0,
          tilt: 0.3,
          scale: 0.9,
          text: "dataScience",
          nextId: 33,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #6
        numberedHotspot(
          longitude: -278,
          latitude: -12,
          rotation: 0,
          tilt: 0.3,
          scale: 0.9,
          text: "go to ground floor",
          nextId: 36,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 32  psycholgy
        // Hotspot #1
        numberedHotspot(
          longitude: -50,
          latitude: -5.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "outside first floor ",
          nextId: 26,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 33  dataScience

        // Hotspot #1
        numberedHotspot(
          longitude: 45,
          latitude: -3.0,
          rotation: 0,
          tilt: 0,
          scale: 1,
          text: "go to first floor side",
          nextId: 31,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 34  pentagon1
        // Hotspot #1
        numberedHotspot(
          longitude: 108.0,
          latitude: -4.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "outdoor pentagon",
          nextId: 35,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 240,
          latitude: -2.0,
          rotation: 0,
          tilt: 0.3,
          scale: 0.9,
          text: "go to first floor side",
          nextId: 31,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 35  pentagon_outdoor
        // Hotspot #1
        numberedHotspot(
          longitude: 162.0,
          latitude: -2.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "indoor pentagon",
          nextId: 34,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 36  groundfloor
        // Hotspot #1
        numberedHotspot(
          longitude: 195.0,
          latitude: -1.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "go to blue whale",
          nextId: 42,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 237.0,
          latitude: -1.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "go to first floor ",
          nextId: 31,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: 290.0,
          latitude: -1.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "go to cafe hall ",
          nextId: 19,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: 390.0,
          latitude: -6.0,
          rotation: -pi/2,
          tilt: 0,
          scale: 1.0,
          text: "go to ground floor path ",
          nextId: 18,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 37  paneeplane
        // Hotspot #1
        numberedHotspot(
          longitude: 162.0,
          latitude: -2.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "indoor pentagon",
          nextId: 34,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 38  centerofnano
        // Hotspot #1
        numberedHotspot(
          longitude: 195.0,
          latitude: -6.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "outside first floor",
          nextId: 26,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 39  outdoor1
        // Hotspot #1
        numberedHotspot(
          longitude: 260.0,
          latitude: -2.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "go back to cafe hall",
          nextId: 19,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 110.0,
          latitude: -20.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "go to outdoor2",
          nextId: 40,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 40  outdoor2
        // Hotspot #1
        numberedHotspot(
          longitude: 162.0,
          latitude: -8.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "back to outdoor1",
          nextId: 39,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 12,
          latitude: -8.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 1.0,
          text: "go to outdoor3",
          nextId: 41,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 41  outdoor3
        // Hotspot #1
        numberedHotspot(
          longitude: 50.0,
          latitude: -10.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "back to outdoor2",
          nextId: 40,
          style: ArrowStyle( imageUrl: 'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [ //image 42  bluewhale room
        // Hotspot #1
        numberedHotspot(
          longitude: 60.0,
          latitude: -2.0,
          rotation: 0.0,
          tilt: 0,
          scale: 1.0,
          text: "back to ground floor side",
          nextId: 36,
          style: ArrowStyle( imageUrl: 'assets/MRF/door.gif', color: Colors.white,),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      // All remaining 36 panorama definitions with complete hotspots...
      // For brevity showing pattern - in actual implementation, include all 43 complete arrays
    ];
  }

  Hotspot _createTripodHotspot() {
    return Hotspot(
      latitude: -90.0,
      longitude: 26.0,
      width: 700,
      height: 700,
      widget: Image.asset(
        'assets/MRF/mcc_tripadlogo.png',
        width: 6000,
        height: 6000,
        fit: BoxFit.contain,
      ),
    );
  }

  Hotspot _createOptimizedHotspot({
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
    required int number,
  }) {
    final String hotspotKey = '$longitude-$latitude-$text';

    if (!_animations.containsKey(hotspotKey)) {
      _hotspotAnimationTypes[hotspotKey] = animationType;

      switch (animationType) {
        case 'pulse':
          _animations[hotspotKey] = Tween<double>(begin: 1.0, end: 1.05).animate(
            CurvedAnimation(parent: _sharedAnimationController, curve: Curves.easeInOut),
          );
          break;
        case 'bounce':
          _animations[hotspotKey] = Tween<double>(begin: 0.0, end: -5.0).animate(
            CurvedAnimation(parent: _sharedAnimationController, curve: Curves.easeInOut),
          );
          break;
        case 'fade':
          _animations[hotspotKey] = Tween<double>(begin: 0.7, end: 1.0).animate(
            CurvedAnimation(parent: _sharedAnimationController, curve: Curves.easeInOut),
          );
          break;
        default:
          _animations[hotspotKey] = Tween<double>(begin: 1.0, end: 1.0).animate(
            CurvedAnimation(parent: _sharedAnimationController, curve: Curves.easeInOut),
          );
      }
    }

    double hotspotWidth = 80 * scale;
    double hotspotHeight = 80 * scale;

    return Hotspot(
      latitude: latitude,
      longitude: longitude,
      width: hotspotWidth,
      height: hotspotHeight,
      widget: _OptimizedHotspotButton(
        text: text,
        onPressed: () {
          if (mounted && nextId != null) {
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
        animation: _animations[hotspotKey]!,
        animationType: _hotspotAnimationTypes[hotspotKey]!,
      ),
    );
  }

  Widget _buildVREye({required double eyeOffset, required bool isLeftEye}) {
    return PanoramaViewer(
      key: ValueKey('vr_${isLeftEye ? 'left' : 'right'}_{$_panoId}_{$_isviewerSpeed}_${_sensorControl.index}'),
      animSpeed: _isviewerSpeed,
      sensorControl: _sensorControl,
      latitude: _initialViews[_panoId]['lat']!,
      longitude: (_initialViews[_panoId]['lon']! + eyeOffset),
      hotspots: panoHotspots[_panoId % _imageNames.length],
      child: Image.asset(
        'assets/MRF/${_imageNames[_panoId % _imageNames.length]}.jpg',
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[800],
          child: const Center(
            child: Icon(Icons.error_outline, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }

  Widget vrWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final eyeWidth = screenWidth / 2;
    final ipdOffset = _vrIPD / 10;

    return Container(
      color: Colors.black,
      child: Row(
        children: [
          Container(
            width: eyeWidth,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white, width: 1)),
            ),
            child: ClipRect(child: _buildVREye(eyeOffset: -ipdOffset, isLeftEye: true)),
          ),
          Container(
            width: eyeWidth,
            child: ClipRect(child: _buildVREye(eyeOffset: ipdOffset, isLeftEye: false)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAppLoading) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/MRF/mcc_tripadlogo.png', width: 150, height: 150, fit: BoxFit.contain),
              const SizedBox(height: 20),
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              const SizedBox(height: 20),
              const Text('Loading Virtual Tour...', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ),
      );
    }

    Widget panoramaWidget = PanoramaViewer(
      animSpeed: _isviewerSpeed,
      key: ValueKey('${_panoId}_${_sensorControl.index}_${_isviewerSpeed}'),
      sensorControl: _sensorControl,
      latitude: _initialViews[_panoId]['lat']!,
      longitude: _initialViews[_panoId]['lon']!,
      hotspots: panoHotspots[_panoId % _imageNames.length],
      child: Image.asset('assets/MRF/${_imageNames[_panoId % _imageNames.length]}.jpg'),
    );

    return Scaffold(
      body: Stack(
        children: [
          _isVRMode ? vrWidget() : panoramaWidget,
          _buildTopLeftLogoAndText(),
          _buildBottomControls(),
          if (isvisble) _buildImageCarousel(),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 15,
      left: 70,
      right: 70,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(" ${_placeNames[_panoId]}"),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isvisble = !isvisble;
                      if (isvisble) _scrollToCurrentImage();
                    });
                  },
                  icon: Icon(isvisble ? Icons.grid_off_sharp : Icons.grid_on_sharp),
                ),
              ],
            ),
            Row(
              children: [
                if (MediaQuery.of(context).size.width >= 659 && MediaQuery.of(context).size.height >= 647)
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.white),
                    onPressed: _showMapDialog,
                  ),
                IconButton(
                  icon: Icon(Icons.vrpano, color: _isVRMode ? Colors.blueAccent : Colors.white),
                  tooltip: _isVRMode ? 'Exit VR Mode' : 'Enter VR Mode',
                  onPressed: () => setState(() => _isVRMode = !_isVRMode),
                ),
                IconButton(
                  color: Colors.white,
                  icon: Icon(_sensorControl == SensorControl.orientation ? Icons.screen_rotation : Icons.pan_tool, color: Colors.white),
                  onPressed: _toggleSensorControl,
                ),
                _buildActionButton(
                  icon: Icons.refresh,
                  tooltip: _isAutoViewer ? "Off auto viewer" : "On auto viewer",
                  isActive: _isAutoViewer,
                  onPressed: _toggleAutoViewer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSensorControl() {
    if (_hasGyroscopePermission) {
      setState(() {
        _sensorControl = _sensorControl == SensorControl.orientation ? SensorControl.none : SensorControl.orientation;
      });
    } else {
      _checkAndRequestDeviceOrientationPermission();
    }
  }

  void _toggleAutoViewer() {
    setState(() {
      _isAutoViewer = !_isAutoViewer;
      _isviewerSpeed = _isAutoViewer ? 1.5 : 0;
    });
  }

  void _showMapDialog() {
    showDialog(
      context: context,
      builder: (_) => _MapOverlayDialog(
        imageNames: _imageNames,
        mapMarkerPositions: _editablePositions,
        currentId: _panoId,
        onJumpToPanorama: (index) {
          setState(() {
            _panoId = index;
            _scrollToCurrentImage();
          });
        },
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Positioned(
      bottom: 60,
      left: 70,
      right: 70,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_imageNames.length, _buildCarouselItem),
                ),
              ),
            ),
            _buildCarouselArrows(),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselItem(int index) {
    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            _panoId = index;
            _scrollToCurrentImage();
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 130,
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(
            color: _panoId == index ? Colors.blueAccent : Colors.white,
            width: _panoId == index ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            SizedBox(
              height: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/MRF/${_imageNames[index]}.jpg', fit: BoxFit.cover),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: 130,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                  color: Colors.black.withOpacity(0.4),
                ),
                child: Text(" ${_placeNames[index]}"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselArrows() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Positioned(
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => _scrollCarousel(-142),
          ),
        ),
        Positioned(
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: () => _scrollCarousel(142),
          ),
        ),
      ],
    );
  }

  void _scrollCarousel(double offset) {
    if (_scrollController.hasClients) {
      double currentOffset = _scrollController.offset;
      double targetOffset = (currentOffset + offset).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(targetOffset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Widget _buildTopLeftLogoAndText() {
    return const Positioned(
      top: 10,
      left: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image(image: AssetImage('assets/MRF/mcc_tripadlogo.png'), width: 60, height: 60),
          SizedBox(width: 8),
          Text('MRF INNOVATION PARK', style: TextStyle(fontFamily: 'Arial', fontSize: 24, color: Color(0x99900000), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Optimized hotspot button widget
class _OptimizedHotspotButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double rotation, tilt, scale;
  final ArrowStyle style;
  final Animation<double> animation;
  final String animationType;

  const _OptimizedHotspotButton({
    required this.text, required this.onPressed, required this.rotation,
    required this.tilt, required this.scale, required this.style,
    required this.animation, required this.animationType,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => GestureDetector(
        onTap: onPressed,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 5, top: 5,
              child: Opacity(
                opacity: 0.3,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateX(tilt)..rotateZ(rotation)..scale(scale),
                  child: _buildArrowImage(Colors.black),
                ),
              ),
            ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateX(tilt)..rotateZ(rotation)..scale(scale),
              child: _buildAnimatedArrow(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedArrow() {
    Widget image = _buildArrowImage(style.color);
    switch (animationType) {
      case 'pulse': return Transform.scale(scale: animation.value, child: image);
      case 'bounce': return Transform.translate(offset: Offset(0, animation.value), child: image);
      case 'fade': return Opacity(opacity: animation.value, child: image);
      default: return image;
    }
  }

  Widget _buildArrowImage(Color color) {
    double finalSize = 120 * scale;

    if (style.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: style.imageUrl!,
        width: finalSize, height: finalSize,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(width: finalSize, height: finalSize, color: Colors.grey),
        errorWidget: (context, url, error) => Container(
          width: finalSize, height: finalSize, color: Colors.grey,
          child: const Center(child: Text('Error', style: TextStyle(color: Colors.red, fontSize: 10))),
        ),
      );
    } else if (style.imagePath != null) {
      return ClipOval(
        child: Image.asset(
          style.imagePath!, width: finalSize, height: finalSize, fit: BoxFit.contain,
          color: color == Colors.transparent ? null : color,
        ),
      );
    }

    return Container(width: finalSize, height: finalSize, color: Colors.grey, child: const Center(child: Icon(Icons.error)));
  }
}

class ArrowStyle {
  final String? imagePath;
  final String? imageUrl;
  final Color color;
  ArrowStyle({this.imagePath, this.imageUrl, required this.color});
}

class _MapOverlayDialog extends StatefulWidget {
  final List<String> imageNames;
  final List<Offset> mapMarkerPositions;
  final int currentId;
  final void Function(int) onJumpToPanorama;

  const _MapOverlayDialog({
    required this.imageNames, required this.mapMarkerPositions,
    required this.currentId, required this.onJumpToPanorama,
  });

  @override
  State<_MapOverlayDialog> createState() => _MapOverlayDialogState();
}

class _MapOverlayDialogState extends State<_MapOverlayDialog> {
  bool _fullscreen = false;

  @override
  Widget build(BuildContext context) {
    final double mapWidth = _fullscreen ? MediaQuery.of(context).size.width * 0.98 : 800;
    final double mapHeight = _fullscreen ? MediaQuery.of(context).size.height * 0.90 : 800;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: _fullscreen ? 0 : 24, vertical: _fullscreen ? 0 : 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: mapWidth, height: mapHeight,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 24)],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: const Image(image: AssetImage('assets/MRF/MMIP_Map.jpg'), fit: BoxFit.cover),
              ),
            ),
            ...List.generate(widget.imageNames.length, (index) {
              final Offset pos = widget.mapMarkerPositions[index];
              final bool isCurrent = widget.currentId == index;
              return Positioned(
                left: pos.dx * mapWidth - 20, top: pos.dy * mapHeight - 40,
                child: Tooltip(
                  message: widget.imageNames[index],
                  child: GestureDetector(
                    onTap: () { Navigator.of(context).pop(); widget.onJumpToPanorama(index); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.orangeAccent : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: isCurrent ? Colors.deepOrange : Colors.black, width: isCurrent ? 4 : 2),
                        boxShadow: isCurrent ? [BoxShadow(color: Colors.orange.withOpacity(0.7), blurRadius: 12)] : [],
                      ),
                      child: Center(
                        child: Icon(Icons.location_on, color: isCurrent ? Colors.white : Colors.deepOrange, size: 28),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Positioned(
              top: 16, right: 60,
              child: IconButton(
                icon: Icon(_fullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white, size: 32),
                tooltip: _fullscreen ? 'Exit Fullscreen' : 'Fullscreen',
                onPressed: () => setState(() => _fullscreen = !_fullscreen),
              ),
            ),
            Positioned(
              top: 16, right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Utility functions
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