//import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';
//import 'dart:nativewrappers/_internal/vm/lib/isolate_patch.dart' hide ReceivePort, Isolate;
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:js' as js; // Import for JavaScript interop

void main() => runApp(const MyApp());
final ScrollController _scrollController = ScrollController();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MCC MRF Innovation Park  360°',
      debugShowCheckedModeBanner: true,
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
  bool isUiAct = false;

  // Add state for sensor control and VR mode
  SensorControl _sensorControl = SensorControl.orientation;
  bool _isVRMode = false;
  bool _isAutoViewer = false;
  double _isviewerSpeed = 0.0;
  bool _hasGyroscopePermission = false; // New state for gyroscope permission
  bool _isAppLoading = true; // New state for preloader
  double _vrIPD = 65.0;

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      child: IconButton(
        color: isActive ? Colors.blueAccent : Colors.white,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
      ),
    );
  }

  final List<List<String>> mapPlaces = [
    //ground floor map places
    ['enterence', '0'],
    ['innovation parlc', '2'],
    ['conference room', '6'],
    ['unicorn room', '7'],
    ['center for BF', '8'],
    ['ground floor', '9'],
    ['Cafe', '19'],
    ['ground floor side', '36'],
    ['outdoor2', '40'],
    ['outdoor3', '41'],
    ['blueWhaleroom', '42'],
    //first floor map places
    ['first floor', '26'],
    ['center for HR', '28'],
    ['center for BDA', '30'],
    ['center for PR', '32'],
    ['center for CI ', '33'],
    ['paper plane', '38'],
    ['dsri', '34'],
    ['dsri_lab', '35'],
  ];

  final List<String> imageNames = [
    'enterence',
    'enterence2',
    'innovation_parlc',
    'zebra1',
    'unicornMeet',
    'path_to_gf',
    'mini_con',
    'unicorn_room',
    'center_for_BF',
    'ground_lift',
    'center_for_nmr',
    'lab2',
    'lab3',
    'lab4',
    'lab5',
    'lab6',
    'lab7',
    'lab8',
    'ground_staircase',
    'cafe2',
    'Cafe1',
    'fub_enterence',
    'fab_1',
    'fub2',
    'fub3',
    'thinking_space',
    'firstFoolr_staircase',
    'first_floor_path', // first_floor
    'center_for_hr', //center_for_hr
    'center_for_hr_2', //center_for_hr
    'center_for_bda', //center_for_bda
    'first_floor_side', //first_floor_side
    'center_for_pr', //center_for_pr
    'center_for_ci', //center_for_ci
    'dsri',
    'dsri_lab',
    'ground_floor_side', //ground_floor_side
    'startup_room', //startup_room
    'paper_plane', //paper_plane
    'outdoor1',
    'outdoor2',
    'outdoor3',
    'blueWhaleroom',
  ];
  final List<String> placeNames = [
    'Enterence',
    'Path to Parlc',
    'Innovation Parlc',
    'Zebra Room',
    'Camel Room',
    'Path to GF',
    'Conference Room',
    'Unicorn Room',
    'Center for BF',
    'Ground Floor',
    'Center for NMR',
    'Lab 1',
    'Lab 2',
    'Lab 3',
    'Lab 4',
    'Lab 5',
    'Lab 6',
    'Lab 7',
    'GF path',
    'Cafe Hall',
    'Cafe',
    'Fab Stairs',
    'Fab Lab 1',
    'Fab Lab 2',
    'Fab Lab 3',
    'Thinking Space',
    'FirstFloor',
    'FF Path',
    'Center for HR',
    'Center for HR ',
    'Center for BDA',
    'First Floor',
    'Center for PR',
    'Center for CI',
    'DSRI Lab',
    'DSRI Lab',
    'GF side',
    'Startup room',
    'PaperPlane',
    'Outdoor 1',
    'Outdoor 2',
    'Outdoor 3',
    'BlueWhale Room',
  ];

  final List<Map<String, double>> initialViews = [
    {'lat': -6.0, 'lon': -145.0}, // Image 0: Entrance
    {'lat': 4.0, 'lon': -145.0}, // Image 1: enterance
    {'lat': 3.0, 'lon': 110.0}, // Image 2: perlc
    {'lat': -5.0, 'lon': 10.0}, // Image 3: zebra
    {'lat': 0.0, 'lon': 0.0}, // Image 4: camel
    {'lat': -10.0, 'lon': -100.0}, // Image 5: center of bus
    {'lat': 0.0, 'lon': 175}, // Image 6: 'mini_con'
    {'lat': 5.0, 'lon': 358}, // Image 7: 'statupmeet'
    {'lat': 0.0, 'lon': -175}, // Image 8: 'researchroom'
    {'lat': -5.0, 'lon': 150}, // Image 9: 'ground_lift'
    {'lat': 0.5, 'lon': 100}, // Image 10: 'lab1'
    {'lat': -10, 'lon': -60}, // Image 11: 'lab2'
    {'lat': 0.0, 'lon': -70}, // Image 12: 'lab3'
    {'lat': -5.0, 'lon': 105}, // Image 13: 'lab4'
    {'lat': -5.0, 'lon': -85.0}, // Image 14: 'lab5'
    {'lat': -5.0, 'lon': -180.0}, // Image 15: 'lab6'
    {'lat': -5.0, 'lon': -345.0}, // Image 16: 'lab7'
    {'lat': -5.0, 'lon': -180.0}, // Image 17: 'lab8'
    {'lat': -5.0, 'lon': -170.0}, // Image 18: 'ground floor'
    {'lat': -5.0, 'lon': -180.0}, // Image 19: 'cafe hall'
    {'lat': -5.0, 'lon': -85.0}, // Image 20: 'cafe  '
    {'lat': 5.0, 'lon': -360.0}, // Image 21: 'fab enterence'
    {'lat': -5.0, 'lon': -360.0}, // Image 22: 'fab1'
    {'lat': -5.0, 'lon': -180.0}, // Image 23: 'fab2'
    {'lat': -5.0, 'lon': -180.0}, // Image 24: 'fab3'
    {'lat': -5.0, 'lon': -195.0}, // Image 25: 'thinking space'
    {'lat': -5.0, 'lon': -360.0}, // Image 26: 'first floor'
    {'lat': -5.0, 'lon': -180.0}, // Image 27: 'frist floor path'
    {'lat': -3.0, 'lon': -355.0}, // Image 28: 'hub 1'
    {'lat': -3.0, 'lon': -90.0}, // Image 29: 'hub 2'
    {'lat': -3.0, 'lon': -80.0}, // Image 30: 'computional lab'
    {'lat': -3.0, 'lon': -100.0}, // Image 31: 'first floor side'
    {'lat': -5.0, 'lon': -240.0}, // Image 32: 'psycholgy'
    {'lat': -3.0, 'lon': -110.0}, // Image 33: 'dataScience'
    {'lat': -5.0, 'lon': -260.0}, // Image 34: 'pentagon1'
    {'lat': -3.0, 'lon': -35.0}, // Image 35: 'pentagon_outdoor'
    {'lat': -5.0, 'lon': -295.0}, // Image 36: 'groundFloor'
    {'lat': -5.0, 'lon': -180.0}, // Image 37: 'paneePlane'
    {'lat': -5.0, 'lon': -350.0}, // Image 38: 'centerOfNano'
    {'lat': -3.0, 'lon': -270.0}, // Image 39: 'outdoor1'
    {'lat': -3.0, 'lon': 15.0}, // Image 40: 'outdoor2'
    {'lat': -2.0, 'lon': -160.0}, // Image 41: 'outdoor3'
    {'lat': -2.0, 'lon': -270.0}, // Image 42: 'bluewhale'
  ];

  // final GlobalKey<PanoramaViewerState> _panoramaKey = GlobalKey<PanoramaViewerState>();
  Map<String, AnimationController> _controllers = {};
  Map<String, Animation<double>> _animations = {};

  // Normalized (0-1) positions for each panorama on the new site map image
  // These are best-guess mappings to the blue pins on the map, adjust as needed for accuracy

  final List<Offset> mapMarkerPositions = [
    //ground floor map places
    Offset(0.4900, 0.5400),
    Offset(0.5437, 0.4300),
    Offset(0.6400, 0.3300),
    Offset(0.6400, 0.4300),
    Offset(0.7800, 0.3500),
    Offset(0.5500, 0.3050),
    Offset(0.4000, 0.2100),
    Offset(0.3000, 0.2200),
    Offset(0.6000, 0.1600),
    Offset(0.7700, 0.2500),
    Offset(0.2400, 0.1300),

    //first floor map places
    Offset(0.5500, 0.8500),
    Offset(0.6000, 0.7500),
    Offset(0.3950, 0.7137),

    Offset(0.7700, 0.8600),
    Offset(0.2200, 0.6200),
    Offset(0.6600, 0.8000),
    Offset(0.3850, 0.5950),
    Offset(0.4900, 0.6100),
  ];
  final List<Offset> mapMarkerPositions_mobile = [
    //ground floor map places
    Offset(0.5800, 0.5200),
    Offset(0.7100, 0.4500),
    Offset(0.7200, 0.3600),
    Offset(0.6400, 0.4500),
    Offset(0.8200, 0.3500),
    Offset(0.6300, 0.3700),
    Offset(0.5000, 0.2400),
    Offset(0.4200, 0.2700),
    Offset(0.6700, 0.1800),
    Offset(0.8200, 0.2800),
    Offset(0.3600, 0.1500),

    //first floor map places
    Offset(0.6300, 0.8500),
    Offset(0.6800, 0.7500),
    Offset(0.5000, 0.7137),

    Offset(0.8000, 0.8800),
    Offset(0.3500, 0.6500),
    Offset(0.7300, 0.8100),
    Offset(0.4900, 0.6100),
    Offset(0.5700, 0.6200),
  ];
  final List<Offset> mapMarkerPositions_tab = [
    //ground floor map places
    Offset(0.5750, 0.5200),
    Offset(0.6400, 0.4300),
    Offset(0.7500, 0.3500),
    Offset(0.7400, 0.4300),
    Offset(0.8850, 0.3600),
    Offset(0.6500, 0.3400),
    Offset(0.4800, 0.2500),
    Offset(0.3800, 0.2400),
    Offset(0.7000, 0.1800),
    Offset(0.8800, 0.2800),
    Offset(0.2900, 0.1600),

    //first floor map places
    Offset(0.6600, 0.8100),
    Offset(0.7000, 0.7400),
    Offset(0.4800, 0.7000),

    Offset(0.8700, 0.8400),
    Offset(0.2800, 0.6200),
    Offset(0.7700, 0.7850),
    Offset(0.4650, 0.5850),
    Offset(0.5800, 0.6050),
  ];

  List<Offset> _editablePositions = [];
  List<Offset> _editablePositions_mobile = [];
  List<Offset> _editablePositions_tab = [];

  @override
  void initState() {
    super.initState();
    _checkAndRequestDeviceOrientationPermission(); // Call this early
    _loadMarkerPositions();
    _editablePositions = List<Offset>.from(mapMarkerPositions);
    _editablePositions_mobile = List<Offset>.from(mapMarkerPositions_mobile);
    _editablePositions_tab = List<Offset>.from(mapMarkerPositions_tab);
    // Set a small delay for the preloader to be visible
    Future.delayed(const Duration(milliseconds: 5000), () {
      // Adjust delay as needed
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
    _controllers.clear();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentImage(int duration) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        const double imageWidth = 130.0;
        const double imageMargin = 12.0;
        const double totalImageWidth = imageWidth + imageMargin;

        // Get screen width to calculate center offset
        final double screenWidth = MediaQuery.of(context).size.width;
        final double containerWidth = screenWidth - 140;

        // Calculate the scroll position to center the current image
        double targetOffset =
            (_panoId * totalImageWidth) -
            (containerWidth / 2) +
            (imageWidth / 2);

        // Ensure the offset is within valid bounds
        targetOffset = targetOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );

        // double offset = (_panoId * 70.0) - (MediaQuery.of(context).size.width / 2) + 35.0;
        // offset = offset.clamp(0.0, _scrollController.position.maxScrollExtent);
        //create isolate

        _scrollController.animateTo(
          targetOffset,
          duration: Duration(milliseconds: duration),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadMarkerPositions() async {
    final loaded = await loadMarkerPositions(mapMarkerPositions.length);
    final loadedMb = await loadMarkerPositions(
      mapMarkerPositions_mobile.length,
    );
    final loadedTb = await loadMarkerPositions(mapMarkerPositions_tab.length);
    if (loaded != null && loadedMb != null && loadedTb != null) {
      setState(() {
        for (int i = 0; i < loaded.length; i++) {
          mapMarkerPositions[i] = loaded[i];
          mapMarkerPositions_mobile[i] = loadedMb[i];
          mapMarkerPositions_tab[i] = loadedTb[i];
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
        final String? permissionState =
            await js.context['DeviceOrientationEvent'].callMethod(
                  'requestPermission',
                )
                as String?;
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
        _sensorControl =
            SensorControl.orientation; // Enable gyroscope by default
      });
      print(
        "Device Orientation Event available (no explicit permission needed).",
      );
    }
  }

  List<List<Hotspot>> get panoHotspots {
    // Define the tripod logo hotspot
    Hotspot tripodLogoHotspot = hotspot(
      longitude: 26.0,
      latitude: -90.0,
      rotation: 0,
      tilt: 0.0,
      scale: 0.9,
      text: "logo-tripod",
      nextId: null,
      style: ArrowStyle(
        imagePath: 'assets/MRF/tripodLogo.png',
        color: Colors.transparent,
      ),
      animationType: 'pulse',
      animationDuration: 20,
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
      [
        // Hotspot # 1:
        numberedHotspot(
          longitude: -180.0,
          latitude: -12.0,
          rotation: -50.1,
          tilt: 0.8,
          scale: 0.9,
          text: "Go Forward",
          nextId: 1,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'none',
          animationDuration: 5,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 1: enterance2
      [
        // Hotspot #2: Enter Enterance2 (to image 2: 10)
        numberedHotspot(
          longitude: -138.0,
          latitude: 2.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "Enter enterance2",
          nextId: 2,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'bounce',
          animationDuration: 1500,
        ), // image #2,(hotspot: 1)

        numberedHotspot(
          longitude: 16.0,
          latitude: -17.0,
          rotation: -50.2,
          tilt: 0.4,
          scale: 0.9,
          text: "back to enterance",
          nextId: 0,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'bounce',
          animationDuration: 1500,
        ), // image #2,(hotspot: 2)
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 2: parlv
      [
        // Hotspot #1
        numberedHotspot(
          longitude: 132.0,
          latitude: 0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "Next to center of bus",
          nextId: 5,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 96.0,
          latitude: 0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "Next to camel",
          nextId: 4,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -75.0,
          latitude: -0.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "Back to enterance2 ",
          nextId: 1,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: 86.0,
          latitude: 0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "next zebra ",
          nextId: 3,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 3:zerbra
      [
        // Hotspot #1
        numberedHotspot(
          longitude: -203.0,
          latitude: -17.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "Return to parlc",
          nextId: 2,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'bounce',
          animationDuration: 1200,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 4: camel
      [
        // Hotspot #1
        numberedHotspot(
          longitude: 214.0,
          latitude: -17.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "back to Parlc",
          nextId: 2,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'bounce',
          animationDuration: 1000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 5: center of bus
      [
        // Hotspot #1
        numberedHotspot(
          longitude: -77.0,
          latitude: .0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "mini conference",
          nextId: 6,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 250.0,
          latitude: -20.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "ground Floor lift",
          nextId: 9,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: 150.0,
          latitude: 1.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "back to perlc",
          nextId: 2,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: 127.0,
          latitude: 0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to unicorn",
          nextId: 7,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #5
        numberedHotspot(
          longitude: 718.0,
          latitude: 0.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "research room",
          nextId: 8,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #11
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 6: mini conferen
      [
        // Hotspot #1
        numberedHotspot(
          longitude: -689.0,
          latitude: -10.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "back to center of bus",
          nextId: 5,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'bounce',
          animationDuration: 1200,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      // =============================
      // Image 7: unicorn (startup meet)
      [
        // Hotspot #1
        numberedHotspot(
          longitude: 329.0,
          latitude: -3.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "Back to center of bus",
          nextId: 5,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
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
          longitude: -29.0,
          latitude: -3.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "back to center of bus",
          nextId: 5,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
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
          longitude: 10,
          latitude: -10.0,
          rotation: 0,
          tilt: 0.5,
          scale: 0.9,
          text: "go to first floor ",
          nextId: 26,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ), //
        // Hotspot #2
        numberedHotspot(
          longitude: -60.0,
          latitude: -25.0,
          rotation: -pi,
          tilt: 2.0,
          scale: 0.9,
          text: "back to center of bus",
          nextId: 5,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: 80,
          latitude: -25.0,
          rotation: -pi,
          tilt: 2.0,
          scale: 0.9,
          text: "cafe path",
          nextId: 18,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: 148.0,
          latitude: -3.0,
          rotation: 0,
          tilt: 0.0,
          scale: 0.9,
          text: "enter lab",
          nextId: 10,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
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
          scale: 0.9,
          text: "Return to ground floor lift",
          nextId: 9,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'bounce',
          animationDuration: 1000,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 90,
          latitude: -2.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to lab2 ",
          nextId: 11,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -193,
          latitude: -1.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to lab5",
          nextId: 14,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: 135,
          latitude: -2.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to lab8",
          nextId: 17,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
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
          scale: 0.9,
          text: "Back to lab1",
          nextId: 10,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: -62,
          latitude: -8.5,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to lab3",
          nextId: 12,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -22.8,
          latitude: -6,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to lab4",
          nextId: 13,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
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
          scale: 0.9,
          text: "Back to lab 2",
          nextId: 11,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      // =============================
      [
        // #iamge 13:lab4
        // Hotspot #1
        numberedHotspot(
          longitude: -36,
          latitude: -7,
          rotation: 0.0,
          tilt: 0.3,
          scale: 0.9,
          text: "back to lab2",
          nextId: 11,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [
        // #iamge 14 :lab5
        // Hotspot #1
        numberedHotspot(
          longitude: 07,
          latitude: -5.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "back to lab 1",
          nextId: 10,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 130.0,
          latitude: -9.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to lab6",
          nextId: 15,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [
        // #iamge 15 lab6
        // Hotspot #1
        numberedHotspot(
          longitude: -140.0,
          latitude: -5,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "go to lab7",
          nextId: 16,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: -22,
          latitude: -5,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "back to lab5",
          nextId: 14,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [
        // #iamge 16 lab7
        // Hotspot # 1
        numberedHotspot(
          longitude: -138.0,
          latitude: -5,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "back to lab6",
          nextId: 15,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [
        // #iamge 17 :lab8
        // Hotspot #1
        numberedHotspot(
          longitude: -170.0,
          latitude: -5,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "back to lab1",
          nextId: 10,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: -38,
          latitude: -14.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to lab2",
          nextId: 11,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [
        // #iamge 18 :ground floor
        // Hotspot #1
        numberedHotspot(
          longitude: 10,
          latitude: -25.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 0.9,
          text: "back to ground floor lift",
          nextId: 9,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ), // #28
        // Hotspot #2
        numberedHotspot(
          longitude: -163,
          latitude: -7,
          rotation: pi / 2,
          tilt: 0,
          scale: 0.9,
          text: "go to cafe",
          nextId: 19,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -170,
          latitude: 2.0,
          rotation: 0,
          tilt: 0.4,
          scale: 0.85,
          text: "first floor stair",
          nextId: 31,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: -170,
          latitude: -4.0,
          rotation: pi / 2,
          tilt: 0.4,
          scale: 0.85,
          text: "go to ground floor side",
          nextId: 36,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [
        // #iamge 19 : cafe
        // Hotspot #1
        numberedHotspot(
          longitude: -180.0,
          latitude: -25.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 0.9,
          text: "go inside cafe",
          nextId: 20,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
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
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -125.0,
          latitude: -2.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 0.9,
          text: "go outdoor1",
          nextId: 39,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: -275.0,
          latitude: -2.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 0.9,
          text: "go inside cafe",
          nextId: 36,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],

      [
        //image 20 cafe 2
        // Hotspot #1
        numberedHotspot(
          longitude: 80.0,
          latitude: -5.0,
          rotation: 0.0,
          tilt: 1,
          scale: 0.9,
          text: "back to hall",
          nextId: 19,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
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
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
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
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 21 fab enterane
        // Hotspot #1
        numberedHotspot(
          longitude: 0,
          latitude: -5.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 0.9,
          text: "go to fab1",
          nextId: 22,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
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
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #29
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 22 fab1
        // Hotspot #1
        numberedHotspot(
          longitude: -10,
          latitude: 0.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "go to fab2",
          nextId: 23,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 200,
          latitude: -25,
          rotation: pi / 2,
          tilt: 0,
          scale: 0.9,
          text: "go to enterence",
          nextId: 21,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
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
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 23 fab2
        // Hotspot #28: Entrance (to image 3: 5)
        numberedHotspot(
          longitude: 18.0,
          latitude: -10.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "back to fab1",
          nextId: 22,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 24 fab3
        // Hotspot #29: Mountain (to image 10: 3)
        numberedHotspot(
          longitude: -300.0,
          latitude: -5.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "back to fab1",
          nextId: 22,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ), // #29
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 25 thinking space
        // Hotspot #28: Entrance (to image 3: 5)
        numberedHotspot(
          longitude: -10.0,
          latitude: 5,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "back to cafe",
          nextId: 20,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 26 first floor
        // Hotspot #1
        numberedHotspot(
          longitude: -100,
          latitude: -25.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 0.9,
          text: "back to ground ground floor  lift",
          nextId: 9,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: -22,
          latitude: -1,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to hub",
          nextId: 28,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -35,
          latitude: -10.0,
          rotation: -pi / 2,
          tilt: 0,
          scale: 0.9,
          text: "first floor path",
          nextId: 27,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        numberedHotspot(
          longitude: 37.0,
          latitude: -2.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to pys lab",
          nextId: 32,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
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
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #6
        numberedHotspot(
          longitude: 145.0,
          latitude: -30.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to panner",
          nextId: 37,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 27 first floor path
        // Hotspot #1
        numberedHotspot(
          longitude: -172.0,
          latitude: -9.0,
          rotation: pi / 2,
          tilt: 0,
          scale: 0.9,
          text: "go compution lab ",
          nextId: 30,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
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
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: 180,
          latitude: -2.0,
          rotation: pi / 2,
          tilt: 0,
          scale: 0.7,
          text: "go to first floor side",
          nextId: 31,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 28 hub1
        // Hotspot #1
        numberedHotspot(
          longitude: 113.8,
          latitude: -3,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "go outside",
          nextId: 26,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 80,
          latitude: -10.0,
          rotation: -pi / 2,
          tilt: 0,
          scale: 0.9,
          text: "go up floor",
          nextId: 29,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 29 hub2
        // Hotspot #1
        numberedHotspot(
          longitude: 50,
          latitude: -20.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 0.9,
          text: "go down floor",
          nextId: 28,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 30 computional lab
        // Hotspot #1
        numberedHotspot(
          longitude: 77.0,
          latitude: -2.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "first floor path",
          nextId: 27,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
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
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 31 first floor side
        // Hotspot #1
        numberedHotspot(
          longitude: -110.0,
          latitude: -10.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 0.85,
          text: "back to first floor path",
          nextId: 27,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
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
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: -265.0,
          latitude: -1,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to pentagon",
          nextId: 34,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
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
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot #5
        numberedHotspot(
          longitude: -306,
          latitude: -1.0,
          rotation: 0,
          tilt: 0.3,
          scale: 0.9,
          text: "dataScience",
          nextId: 33,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
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
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 32  psycholgy
        // Hotspot #1
        numberedHotspot(
          longitude: -48,
          latitude: -5.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "outside first floor ",
          nextId: 26,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),

        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 33  dataScience

        // Hotspot #1
        numberedHotspot(
          longitude: 42,
          latitude: -4.0,
          rotation: 0,
          tilt: 0,
          scale: 0.9,
          text: "go to first floor side",
          nextId: 31,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 34  pentagon1
        // Hotspot #1
        numberedHotspot(
          longitude: 108.0,
          latitude: -4.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "DSRI room",
          nextId: 35,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 239,
          latitude: -2.0,
          rotation: 0,
          tilt: 0.3,
          scale: 0.9,
          text: "go to first floor side",
          nextId: 31,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'fade',
          animationDuration: 2000,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 35  pentagon_outdoor
        // Hotspot #1
        numberedHotspot(
          longitude: 162.0,
          latitude: -2.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "pentengon room",
          nextId: 34,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 36  groundfloor side
        // Hotspot #1
        numberedHotspot(
          longitude: 198.5,
          latitude: -1.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "go to blue whale",
          nextId: 42,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 237.0,
          latitude: -1.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "go to first floor ",
          nextId: 31,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #3
        numberedHotspot(
          longitude: 290.0,
          latitude: -1.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "go to cafe hall ",
          nextId: 19,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #4
        numberedHotspot(
          longitude: 390.0,
          latitude: -6.0,
          rotation: -pi / 2,
          tilt: 0,
          scale: 0.9,
          text: "go to ground floor path ",
          nextId: 18,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 37  paneeplane
        // Hotspot #1
        numberedHotspot(
          longitude: 235.0,
          latitude: -0.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "go to first floor stair case",
          nextId: 26,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 38  centerofnano
        // Hotspot #1
        numberedHotspot(
          longitude: 200.8,
          latitude: -6.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "outside first floor",
          nextId: 26,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 39  outdoor1
        // Hotspot #1
        numberedHotspot(
          longitude: 260.0,
          latitude: -2.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "go back to cafe hall",
          nextId: 19,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 128.0,
          latitude: -27.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "go to outdoor2",
          nextId: 40,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 40  outdoor2
        // Hotspot #1
        numberedHotspot(
          longitude: 162.0,
          latitude: -8.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 0.9,
          text: "back to outdoor1",
          nextId: 39,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot #2
        numberedHotspot(
          longitude: 12,
          latitude: -8.0,
          rotation: 0.0,
          tilt: 0.5,
          scale: 0.9,
          text: "go to outdoor3",
          nextId: 41,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 41  outdoor3
        // Hotspot #1
        numberedHotspot(
          longitude: 50.0,
          latitude: -10.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "back to outdoor2",
          nextId: 40,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/X9Tv65D85uClgmPK3Bwe.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
        // Hotspot: Tripod Logo (covers tripod)
        tripodLogoHotspot,
      ],
      [
        //image 42  bluewhale room
        // Hotspot #1
        numberedHotspot(
          longitude: 59.3,
          latitude: -2.0,
          rotation: 0.0,
          tilt: 0,
          scale: 0.9,
          text: "back to ground floor side",
          nextId: 36,
          style: ArrowStyle(
            imageUrl:
                'https://assets.panoee.com/statics/hotspot-image/EWHSXHnJvOnaypAMkTzp.png',
            color: Colors.white,
          ),
          animationType: 'pulse',
          animationDuration: 1500,
        ),
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
          _animations[hotspotKey] = Tween<double>(
            begin: 1.0,
            end: 1.05,
          ).animate(
            CurvedAnimation(
              parent: _controllers[hotspotKey]!,
              curve: Curves.easeInOut,
            ),
          );
          break;
        case 'bounce':
          _animations[hotspotKey] = Tween<double>(
            begin: 0.0,
            end: -5.0,
          ).animate(
            CurvedAnimation(
              parent: _controllers[hotspotKey]!,
              curve: Curves.easeInOut,
            ),
          );
          break;
        case 'fade':
          _animations[hotspotKey] = Tween<double>(begin: 0.7, end: 1.0).animate(
            CurvedAnimation(
              parent: _controllers[hotspotKey]!,
              curve: Curves.easeInOut,
            ),
          );
          break;
        case 'none':
          _animations[hotspotKey] = Tween<double>(begin: 1.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controllers[hotspotKey]!,
              curve: Curves.easeInOut,
            ),
          );
          break;
        default:
          _animations[hotspotKey] = Tween<double>(begin: 1.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controllers[hotspotKey]!,
              curve: Curves.easeInOut,
            ),
          );
      }
    }

    // If this is the logo hotspot, make it much larger
    double hotspotWidth = 80 * scale;
    double hotspotHeight = 80 * scale;
    if (style.imagePath != null &&
        style.imagePath!.contains('tripodLogo.png')) {
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
          if (mounted) {
            if (nextId != null) {
              setState(() {
                _panoId = nextId;
                isvisble ? _scrollToCurrentImage(300) : null;
              });
            }
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
    final bool isLogo =
        style.imagePath != null && style.imagePath!.contains('tripodLogo.png');
    return AnimatedBuilder(
      animation: animation,
      builder:
          (_, __) => GestureDetector(
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
                        transform:
                            Matrix4.identity()
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
                  transform:
                      Matrix4.identity()
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
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: image,
        );
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
      return Scaffold(
        body: Container(
          color: Colors.brown, // You can choose any background color
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/MRF/LoadingLogo.png',
                  width:
                      MediaQuery.of(context).size.width < 600
                          ? 125
                          : 150, // Adjust size as needed
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(
                  strokeCap: StrokeCap.round,
                  color: Colors.white,
                  backgroundColor: Colors.grey,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Loading Virtual Tour...',
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget panoramaWidget = PanoramaViewer(
      //key: ValueKey(_panoId.toString() + _sensorControl.toString()),
      animSpeed: _isviewerSpeed,
      key: ValueKey('${_panoId}_${_sensorControl.index}_${_isviewerSpeed}'),
      sensorControl: _sensorControl,
      latitude: initialViews[_panoId]['lat']!,
      longitude: initialViews[_panoId]['lon']!,
      hotspots: panoHotspots[_panoId % imageNames.length],
      child: Image.asset(
        'assets/MRF/${imageNames[_panoId % imageNames.length]}.jpg',
      ),
    );

    // // VR mode:
    Widget _buildVREye({required double eyeOffset, required bool isLeftEye}) {
      return PanoramaViewer(
        key: ValueKey(
          'vr_${isLeftEye ? 'left' : 'right'}_{$_panoId}_{$_isviewerSpeed}_${_sensorControl.index}',
        ),
        animSpeed: _isviewerSpeed,
        sensorControl: SensorControl.orientation,
        latitude: initialViews[_panoId]['lat']!,
        longitude: (initialViews[_panoId]['lon']! + eyeOffset),
        hotspots: panoHotspots[_panoId % imageNames.length],
        child: Image.asset(
          'assets/MRF/${imageNames[_panoId % imageNames.length]}.jpg',
          errorBuilder:
              (context, error, stackTrace) => Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
        ),
      );
    }

    // Enhanced VR Widget with better stereoscopic rendering
    Widget vrWidget() {
      final screenWidth = MediaQuery.of(context).size.width;
      final eyeWidth = screenWidth / 2;
      final ipdOffset = _vrIPD / 10; // Convert mm to degrees roughly

      return Container(
        key: ValueKey('${_panoId}_${_sensorControl.index}_${_isviewerSpeed}'),
        color: Colors.black,
        child: Row(
          children: [
            // Left Eye View
            Container(
              width: eyeWidth,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.white, width: 1),
                ),
              ),
              child: ClipRect(
                child: _buildVREye(eyeOffset: -ipdOffset, isLeftEye: true),
              ),
            ),
            // Right Eye View
            Container(
              width: eyeWidth,
              child: ClipRect(
                child: _buildVREye(eyeOffset: ipdOffset, isLeftEye: false),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _isVRMode
              ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: vrWidget(),
              )
              : AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: panoramaWidget,
              ),
          _buildTopLeftLogo(),
          Positioned(
            bottom: 15,
            left: 20,
            right: 20,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                //border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //row 1 contains name of the place and pop button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      //display place name
                      Text(
                        "  ${placeNames[_panoId]}",
                        style: TextStyle(fontSize: 17),
                      ),
                      //pop up button for slider
                      IconButton(
                        onPressed: () {
                          setState(() {
                            isvisble = !isvisble;
                            isvisble ? _scrollToCurrentImage(1) : null;
                          });
                        },
                        icon: Icon(
                          isvisble ? Icons.grid_off_sharp : Icons.grid_on_sharp,
                        ),
                      ),
                    ],
                  ),
                  // row 2 contains other function button like vrmode,rotate,map,gyro ..
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Map toggle button - show only if screen size is sufficient
                      Builder(
                        builder: (context) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final screenHeight =
                              MediaQuery.of(context).size.height;
                          return screenWidth > 350 && screenHeight > 635
                              ? IconButton(
                                icon: Icon(Icons.map, color: Colors.white),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (_) => _MapOverlayDialog(
                                          mapPlaces: mapPlaces,
                                          mapMarkerPositions:
                                              mapMarkerPositions,
                                          mapMarkerPositions_mobile:
                                              mapMarkerPositions_mobile,
                                          mapMarkerPositions_tab:
                                              mapMarkerPositions_tab,
                                          currentId: _panoId,
                                          onJumpToPanorama: (index) {
                                            setState(() {
                                              _panoId = index;
                                              isvisble
                                                  ? _scrollToCurrentImage(1)
                                                  : null;
                                            });
                                          },
                                        ),
                                  );
                                },
                              )
                              : SizedBox.shrink();
                        },
                      ),
                      //vr mode button
                      Visibility(
                        visible:
                            MediaQuery.of(context).size.width > 600
                                ? true
                                : false,
                        child: IconButton(
                          icon: Icon(
                            Icons.vrpano,
                            color: _isVRMode ? Colors.blueAccent : Colors.white,
                          ),
                          tooltip: _isVRMode ? 'Exit VR Mode' : 'Enter VR Mode',
                          onPressed: () {
                            setState(() {
                              _isVRMode = !_isVRMode;
                            });
                          },
                        ),
                      ),

                      // Gyroscope/touch toggle button
                      Visibility(
                        visible: _hasGyroscopePermission,
                        child: IconButton(
                          color: Colors.white,
                          icon: Icon(
                            _sensorControl == SensorControl.orientation
                                ? Icons.screen_rotation
                                : Icons.pan_tool,
                            color: Colors.white,
                          ),
                          tooltip:
                              _sensorControl == SensorControl.orientation
                                  ? 'Gyroscope ON (Tap to use Touch)'
                                  : 'Touch ON (Tap to use Gyroscope)',
                          onPressed: () {
                            // Only allow toggling if gyroscope is supported and permission is granted
                            if (_hasGyroscopePermission) {
                              setState(() {
                                _sensorControl =
                                    _sensorControl == SensorControl.orientation
                                        ? SensorControl.none
                                        : SensorControl.orientation;
                              });
                            } else {
                              // If gyroscope is not available or permission denied, try to request again
                              _checkAndRequestDeviceOrientationPermission();
                            }
                          },
                        ),
                      ),
                      //auto rotate button
                      _buildActionButton(
                        icon: Icons.refresh,
                        tooltip:
                            _isAutoViewer
                                ? "Off auto viewer"
                                : "On auto viewer ",
                        isActive: _isAutoViewer,
                        onPressed: () {
                          setState(() {
                            _isAutoViewer = !_isAutoViewer;
                            _isviewerSpeed = _isAutoViewer ? 1.5 : 0;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          //image slider
          Visibility(
            visible: isvisble,
            child: Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        //border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: ListView.builder(
                        cacheExtent: 600,
                        addAutomaticKeepAlives: true,
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: 1,
                        itemBuilder: (context, index) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(imageNames.length, (index) {
                              return GestureDetector(
                                onTap: () {
                                  if (mounted) {
                                    setState(() {
                                      _panoId = index;
                                      isvisble
                                          ? _scrollToCurrentImage(300)
                                          : null;
                                    });
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  width: 130,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          _panoId == index
                                              ? Colors.blueAccent
                                              : Colors.white,
                                      width: _panoId == index ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 90,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.asset(
                                            fit: BoxFit.cover,
                                            'assets/MRF/${imageNames[index]}.jpg',
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        child: Container(
                                          width: 130,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(10),
                                              bottomRight: Radius.circular(10),
                                            ),
                                            color: Colors.black.withOpacity(
                                              0.4,
                                            ),
                                          ),
                                          child: Text(" " + placeNames[index]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                    //left arrow button
                    Positioned(
                      left: 8,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () {
                          if (_scrollController.hasClients) {
                            double currentOffset = _scrollController.offset;
                            double targetOffset = (currentOffset - 142).clamp(
                              0.0,
                              _scrollController.position.maxScrollExtent,
                            );
                            _scrollController.animateTo(
                              targetOffset,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                    //right arrow button
                    Positioned(
                      right: 8,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (_scrollController.hasClients) {
                            double currentOffset = _scrollController.offset;
                            double targetOffset = (currentOffset + 142).clamp(
                              0.0,
                              _scrollController.position.maxScrollExtent,
                            );
                            _scrollController.animateTo(
                              targetOffset,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New method to build the logo and text
  Widget _buildTopLeftLogo() {
    return Positioned(
      top: 10,
      left: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/MRF/logo.png',
            width:
                MediaQuery.of(context).size.width < 600
                    ? 70
                    : 120, // Adjust size as needed
            //        height:  MediaQuery.of(context).size.height < 600 ? 125 :150, // Adjust size as needed
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
  if (style.imagePath != null && style.imagePath!.contains('tripodLogo.png')) {
    // Make the logo extremely large to cover the tripod
    return Center(
      child: SizedBox(
        width: 6000, // Even larger for maximum coverage
        height: 6000,
        child: Image.asset(style.imagePath!, fit: BoxFit.contain),
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
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        print('Error loading network image ${style.imageUrl}: $error');
        return Container(
          width: width,
          height: height,
          color: Colors.grey,
          child: Center(
            child: Text(
              'Net Err',
              style: TextStyle(color: Colors.red, fontSize: 10),
            ),
          ),
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
        child: Center(
          child: Text(
            "No Path!",
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      );
    }
    return ClipOval(
      child: Image.asset(
        style.imagePath!,
        width: width,
        height: height,
        fit: BoxFit.contain,
        color: style.color == Colors.transparent ? null : style.color,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          print('Error loading asset ${style.imagePath}: $error');
          return Container(
            width: width,
            height: height,
            color: Colors.grey,
            child: Center(
              child: Text(
                'Asset Err',
                style: TextStyle(color: Colors.red, fontSize: 10),
              ),
            ),
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
  final List<List<String>> mapPlaces;
  final List<Offset> mapMarkerPositions;
  final List<Offset> mapMarkerPositions_mobile;
  final List<Offset> mapMarkerPositions_tab;
  final int currentId;
  final void Function(int) onJumpToPanorama;
  const _MapOverlayDialog({
    required this.mapPlaces,
    required this.mapMarkerPositions,
    required this.mapMarkerPositions_mobile,
    required this.mapMarkerPositions_tab,
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
  List<Offset> _editablePositions_mobile = [];
  List<Offset> _editablePositions_tab = [];

  @override
  void initState() {
    super.initState();
    _editablePositions = List<Offset>.from(widget.mapMarkerPositions);
    _editablePositions_mobile = List<Offset>.from(
      widget.mapMarkerPositions_mobile,
    );
    _editablePositions_tab = List<Offset>.from(widget.mapMarkerPositions_tab);
  }

  //mappppppppppppppppppp
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final double mapWidth = screenWidth > 635 ? 800 - 200 : 350;
    final double mapHeight = screenHeight > 835 ? 800 : 600;

    if (screenWidth >= 1024 && screenHeight >= 1024) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: _fullscreen ? 0 : 24,
          vertical: _fullscreen ? 0 : 24,
        ),
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              width: 600,
              height: 780,
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
                        fit: _fullscreen ? BoxFit.contain : BoxFit.fill,
                      ),
                    ),
                  ),
                  // Markers
                  ...List.generate(widget.mapPlaces.length, (index) {
                    final Offset pos = _editablePositions[index];
                    final bool isCurrent =
                        widget.currentId ==
                        int.parse(widget.mapPlaces[index][1]);
                    return Positioned(
                      left: pos.dx * 600 - 20,
                      top: pos.dy * 800 - 55,
                      child: Tooltip(
                        message: widget.mapPlaces[index][0],
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onJumpToPanorama(
                              int.parse(widget.mapPlaces[index][1]),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 20,
                            child: Center(
                              child: Icon(
                                Icons.location_on,
                                color:
                                    isCurrent
                                        ? Colors.orangeAccent
                                        : Colors.deepOrange,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  // Fullscreen toggle button
                  Positioned(
                    top: 14,
                    right: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white, size: 32),
                        tooltip: 'Close',

                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 135,
                    left: 0,
                    child: Transform.rotate(
                      angle: 55,
                      child: Text(
                        'First Floor',
                        style: TextStyle(color: Colors.black, fontSize: 30),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 165,
                    left: -35,
                    child: Transform.rotate(
                      angle: 55,
                      child: Text(
                        'Ground Floor',
                        style: TextStyle(color: Colors.black, fontSize: 30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (screenWidth > 480 && screenHeight > 700) {
      //tab mapp
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: _fullscreen ? 0 : 24,
          vertical: _fullscreen ? 0 : 24,
        ),
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              width: 480,
              height: 680,
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
                        fit: _fullscreen ? BoxFit.contain : BoxFit.fill,
                      ),
                    ),
                  ),
                  // Markers
                  ...List.generate(widget.mapPlaces.length, (index) {
                    final Offset pos = _editablePositions_tab[index];
                    final bool isCurrent =
                        widget.currentId ==
                        int.parse(widget.mapPlaces[index][1]);
                    return Positioned(
                      left: pos.dx * 435 - 35,
                      top: pos.dy * 735 - 60,
                      child: Tooltip(
                        message: widget.mapPlaces[index][0],
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onJumpToPanorama(
                              int.parse(widget.mapPlaces[index][1]),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 20,
                            child: Center(
                              child: Icon(
                                Icons.location_on,
                                color:
                                    isCurrent
                                        ? Colors.orangeAccent
                                        : Colors.deepOrange,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  // close toggle button
                  Positioned(
                    top: 12,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white, size: 22),
                        tooltip: 'Close',

                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 135,
                    left: -20,
                    child: Transform.rotate(
                      angle: 55,
                      child: Text(
                        'First Floor',
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 165,
                    left: -35,
                    child: Transform.rotate(
                      angle: 55,
                      child: Text(
                        'Ground Floor',
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (screenWidth > 350 && screenHeight > 600) {
      //mobile mapp
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: _fullscreen ? 0 : 24,
          vertical: _fullscreen ? 0 : 24,
        ),
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              width: 300,
              height: 600,
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
                        fit: _fullscreen ? BoxFit.contain : BoxFit.fill,
                      ),
                    ),
                  ),
                  // Markers
                  ...List.generate(widget.mapPlaces.length, (index) {
                    final Offset pos = _editablePositions_mobile[index];
                    final bool isCurrent =
                        widget.currentId ==
                        int.parse(widget.mapPlaces[index][1]);
                    return Positioned(
                      left: pos.dx * 350 - 75,
                      top: pos.dy * 600 - 40,
                      child: Tooltip(
                        message: widget.mapPlaces[index][0],
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onJumpToPanorama(
                              int.parse(widget.mapPlaces[index][1]),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 20,
                            child: Center(
                              child: Icon(
                                Icons.location_on,
                                color:
                                    isCurrent
                                        ? Colors.orangeAccent
                                        : Colors.deepOrange,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  // close toggle button
                  Positioned(
                    top: 12,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white, size: 22),
                        tooltip: 'Close',

                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 135,
                    left: -20,
                    child: Transform.rotate(
                      angle: 55,
                      child: Text(
                        'First Floor',
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 165,
                    left: -35,
                    child: Transform.rotate(
                      angle: 55,
                      child: Text(
                        'Ground Floor',
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
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
