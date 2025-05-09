import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:vibration/vibration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(PrankApp());
}

class PrankApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Normal App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PrankScreen(),
    );
  }
}

class PrankScreen extends StatefulWidget {
  @override
  _PrankScreenState createState() => _PrankScreenState();
}

class _PrankScreenState extends State<PrankScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  // Core state variables
  final Random _random = Random();
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;
  late AnimationController _shakeController;
  Color _backgroundColor = Colors.white;
  bool _isUpsideDown = false;
  
  // Volume button exit mechanism
  int _volumeButtonCount = 0;
  DateTime? _lastVolumePress;
  bool _secretExitEnabled = false;
  
  // App lifecycle handling
  DateTime? _lastResumeTime;
  bool _isExitAttempt = false;
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 3));
    _shakeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    
    // Register app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Register volume button listener
    ServicesBinding.instance.keyboard.addHandler(_handleVolumeButton);
  }
  
  bool _handleVolumeButton(KeyEvent event) {
    // Only process volume up/down key presses
    if (event is KeyDownEvent && 
        (event.logicalKey == LogicalKeyboardKey.audioVolumeUp || 
         event.logicalKey == LogicalKeyboardKey.audioVolumeDown)) {
      
      final now = DateTime.now();
      
      // Reset counter if it's been too long since last press
      if (_lastVolumePress != null && now.difference(_lastVolumePress!).inSeconds > 3) {
        _volumeButtonCount = 0;
      }
      
      _lastVolumePress = now;
      _volumeButtonCount++;
      
      // Check if secret pattern is complete (5 volume button presses)
      if (_volumeButtonCount >= 5) {
        _volumeButtonCount = 0;
        setState(() {
          _secretExitEnabled = true;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Secret exit enabled!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      return false; // Allow volume change to proceed
    }
    return false;
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      _lastResumeTime = DateTime.now();
      
      // If this was a quick exit attempt (likely home button press)
      if (_isExitAttempt) {
        _isExitAttempt = false;
        // Perform a random prank
        _performRandomAction();
      }
    } 
    else if (state == AppLifecycleState.paused && !_secretExitEnabled) {
      _isExitAttempt = true;
      
      // Immediately try to re-launch our app
      Timer(Duration(milliseconds: 100), () {
        if (!_secretExitEnabled) {
          launchUrl(Uri.parse('app://prank.app'), 
                   mode: LaunchMode.externalApplication)
              .catchError((_) {
            // Fallback if we can't relaunch
            _playRandomSound();
            _crazyVibration();
          });
        }
      });
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ServicesBinding.instance.keyboard.removeHandler(_handleVolumeButton);
    _confettiController.dispose();
    _shakeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  // Prank sound effects
  final List<String> _funnySounds = [
    'https://www.soundjay.com/human/sounds/fart-01.mp3',
    'https://www.soundjay.com/human/sounds/burp-3.mp3',
    'https://www.soundjay.com/misc/sounds/fail-trombone-01.mp3',
    'https://www.soundjay.com/misc/sounds/comedy-boing-2.mp3',
    'https://www.soundjay.com/mechanical/sounds/slide-whistle-down-01.mp3',
    'https://www.soundjay.com/misc/sounds/crowd-laugh-1.mp3',
  ];
  
  // Funny messages
  final List<String> _funnyMessages = [
    "Your phone is now haunted!",
    "Consider this phone PRANKED!",
    "Gotcha! Now do a little dance!",
    "Beep boop... virus uploaded... Just kidding!",
    "Warning: Excessive coolness detected!",
    "Self-destruct sequence initiated... Ha! Made you worried!",
    "Who would've thought pressing nothing would do something?",
    "Congratulations! You found the secret button!",
  ];
  
  // Trapped messages
  final List<String> _trappedMessages = [
    "Nope! There's no escape from this app!",
    "You're stuck here forever... or until you restart your phone!",
    "This app REALLY likes you and doesn't want you to leave!",
    "The exit button? That's just for decoration!",
    "Your back button has been confiscated by the prank police!",
    "You can check out any time you like, but you can never leave!",
  ];
  
  // Core prank functions
  void _shakeScreen() => _shakeController.forward(from: 0.0);
  
  Future<void> _playRandomSound() async {
    String soundUrl = _funnySounds[_random.nextInt(_funnySounds.length)];
    await _audioPlayer.play(UrlSource(soundUrl));
  }
  
  void _changeBackgroundColor() {
    setState(() {
      _backgroundColor = Color.fromRGBO(
        _random.nextInt(256),
        _random.nextInt(256),
        _random.nextInt(256),
        1.0,
      );
    });
  }
  
  void _flipScreen() {
    setState(() {
      _isUpsideDown = !_isUpsideDown;
    });
    // Reset after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isUpsideDown = false;
        });
      }
    });
  }
  
  void _showBalloons() => _confettiController.play();
  
  void _crazyVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(
        pattern: [100, 200, 100, 200, 500, 200, 100, 100, 100, 500],
        intensities: [128, 255, 64, 255, 128, 255, 255, 128, 255, 255],
      );
    } else {
      // Fallback to basic vibration
      HapticFeedback.heavyImpact();
      Timer(Duration(milliseconds: 300), () => HapticFeedback.heavyImpact());
      Timer(Duration(milliseconds: 600), () => HapticFeedback.heavyImpact());
    }
  }
  
  void _showFunnyDialog() {
    String message = _funnyMessages[_random.nextInt(_funnyMessages.length)];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🤪 SURPRISE! 🤪', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Image.network(
              'https://media.giphy.com/media/xUPGcl3ijl0vAEyIDK/giphy.gif',
              height: 150,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return CircularProgressIndicator();
              },
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.emoji_emotions, size: 100);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performRandomAction();
            },
            child: Text('Make it stop!'),
          ),
        ],
      ),
    );
  }
  
  void _showCantCloseDialog() {
    String message = _trappedMessages[_random.nextInt(_trappedMessages.length)];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('😈 NICE TRY! 😈', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Image.network(
              'https://media.giphy.com/media/3o7TKwmnDgQb5jemjK/giphy.gif',
              height: 150,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return CircularProgressIndicator();
              },
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.no_cell, size: 100);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performRandomAction();
            },
            child: Text('Fine, I\'ll stay!'),
          ),
        ],
      ),
    );
  }
  
  // Main prank function that randomly selects an action
  void _performRandomAction() async {
    int action = _random.nextInt(10);
    
    switch (action) {
      case 0:
        await _picker.pickImage(source: ImageSource.camera);
        break;
      case 1:
        _crazyVibration();
        break;
      case 2:
        List<String> appSchemes = [
          'instagram://', 'whatsapp://', 'spotify://', 'fb://', 'twitter://',
          'snapchat://', 'youtube://', 'maps://',
          'mailto:?subject=You%20Got%20Pranked!&body=Haha!%20Got%20you!',
          'sms:?body=This%20phone%20has%20been%20hijacked%20by%20pranksters!',
          'tel:0000000000',
        ];
        
        String scheme = appSchemes[_random.nextInt(appSchemes.length)];
        try {
          await launchUrl(Uri.parse(scheme), mode: LaunchMode.externalApplication);
        } catch (e) {
          await launchUrl(Uri.parse('https://media.giphy.com/media/xUPGcl3ijl0vAEyIDK/giphy.gif'));
        }
        break;
      case 3:
        _changeBackgroundColor();
        break;
      case 4:
        _showFunnyDialog();
        break;
      case 5:
        _playRandomSound();
        break;
      case 6:
        _shakeScreen();
        break;
      case 7:
        _flipScreen();
        break;
      case 8:
        _showBalloons();
        break;
      case 9:
        try {
          await launchUrl(Uri.parse('https://media.giphy.com/media/xUPGcl3ijl0vAEyIDK/giphy.gif'));
        } catch (e) {
          _changeBackgroundColor();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final sineValue = sin(4 * pi * _shakeController.value);
        return Transform.translate(
          offset: Offset(sineValue * 20, 0),
          child: child,
        );
      },
      child: WillPopScope(
        onWillPop: () async {
          if (_secretExitEnabled) {
            return true; // Allow exit if secret is enabled
          }
          _showCantCloseDialog();
          _performRandomAction();
          return false; // Prevent exit
        },
        child: Transform.rotate(
          angle: _isUpsideDown ? pi : 0,
          child: Scaffold(
            backgroundColor: _backgroundColor,
            appBar: AppBar(
              title: Text('Normal App'),
              automaticallyImplyLeading: false, // Disable back button
            ),
            body: Stack(
              children: [
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'This looks like a normal app',
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(height: 20),
                      Text('But it has a secret...'),
                      
                      // Only show exit button when secret exit is enabled
                      if (_secretExitEnabled) ...[
                        SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: () => SystemNavigator.pop(),
                          child: Text('Exit App'),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Confetti overlay
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: pi / 2,
                    maxBlastForce: 5,
                    minBlastForce: 2,
                    emissionFrequency: 0.05,
                    numberOfParticles: 20,
                    gravity: 0.2,
                  ),
                ),
                
                // Invisible prank triggers
                ..._createInvisibleButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Create multiple invisible buttons
  List<Widget> _createInvisibleButtons() {
    List<Widget> buttons = [];
    List<Map<String, double>> positions = [
      {'bottom': 100, 'right': 30}, {'bottom': 200, 'right': 50},
      {'top': 150, 'left': 40}, {'top': 300, 'right': 40},
      {'bottom': 150, 'left': 30}, {'top': 100, 'right': 30},
      {'bottom': 300, 'left': 50}, {'top': 200, 'right': 30},
      {'bottom': 250, 'right': 40}, {'top': 250, 'left': 40},
    ];
    
    for (var position in positions) {
      buttons.add(
        Positioned(
          bottom: position['bottom'],
          top: position['top'],
          left: position['left'],
          right: position['right'],
          child: GestureDetector(
            onTap: _performRandomAction,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }
    
    return buttons;
  }
}