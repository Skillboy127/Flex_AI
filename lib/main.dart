import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'screens/login_screen.dart';
import 'services/ai_service.dart';
import 'services/auth_service.dart';

// --- NEW "MIDNIGHT & SAND" PALETTE ---
const Color kColorBackground = Color(0xFF0D1321); // Deepest Navy
const Color kColorCard = Color(0xFF1D2D44);       // Dark Navy
const Color kColorPrimary = Color(0xFF748CAB);    // Steel Blue
const Color kColorAccent = Color(0xFFF0EBD8);     // Sand/Beige (Text & Highlights)

bool? seenOnboarding;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Flex",
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: kColorBackground,
      primaryColor: kColorPrimary,
      cardColor: kColorCard,
      colorScheme: ColorScheme.dark(
        primary: kColorPrimary, 
        secondary: kColorAccent, 
        surface: kColorCard
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: kColorAccent, // Sets default text to Sand
        displayColor: kColorAccent,
      ),
      appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
    ),
    home: seenOnboarding == true ? AuthWrapper() : OnboardingScreen(),
  ));
}

// --- ONBOARDING SCREEN ---
class OnboardingScreen extends StatefulWidget {
  @override _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {"title": "Welcome to Flex", "desc": "Your AI-powered strength & recovery coach. Train smarter, not harder.", "icon": Icons.fitness_center_rounded, "color": kColorAccent},
    {"title": "Smart Features", "desc": "Save your favorite workouts and vibe with our Spotify integration.", "icon": Icons.music_note_rounded, "color": kColorPrimary},
    {"title": "Instant Demos", "desc": "Confused by an exercise? Tap its name to instantly watch a video demo.", "icon": Icons.play_circle_filled_rounded, "color": Color(0xFF3E5C76)}, // Using the Mid-Blue here
  ];

  void _finishOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AuthWrapper()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(padding: EdgeInsets.all(30), decoration: BoxDecoration(color: _pages[index]['color'].withOpacity(0.1), shape: BoxShape.circle), child: Icon(_pages[index]['icon'], size: 100, color: _pages[index]['color'])),
                        SizedBox(height: 40),
                        Text(_pages[index]['title'], textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: kColorAccent)),
                        SizedBox(height: 20),
                        Text(_pages[index]['desc'], textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 16, color: kColorAccent.withOpacity(0.6), height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: List.generate(_pages.length, (index) => AnimatedContainer(duration: Duration(milliseconds: 300), margin: EdgeInsets.only(right: 8), height: 8, width: _currentPage == index ? 24 : 8, decoration: BoxDecoration(color: _currentPage == index ? kColorPrimary : kColorCard, borderRadius: BorderRadius.circular(4))))),
                  ElevatedButton(
                    onPressed: () { if (_currentPage == _pages.length - 1) _finishOnboarding(); else _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease); },
                    style: ElevatedButton.styleFrom(backgroundColor: kColorPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    child: Text(_currentPage == _pages.length - 1 ? "GET STARTED" : "NEXT", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: kColorBackground)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- AUTH WRAPPER ---
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Scaffold(backgroundColor: kColorBackground, body: Center(child: CircularProgressIndicator(color: kColorPrimary)));
        if (snapshot.hasData) return SplashScreen();
        return LoginScreen();
      },
    );
  }
}

// --- HELPER: ICON MAPPER ---
IconData _getExerciseIcon(String name) {
  name = name.toLowerCase();
  if (name.contains("run") || name.contains("cardio") || name.contains("treadmill") || name.contains("cycle") || name.contains("bike") || name.contains("swim") || name.contains("row") || name.contains("jump")) return Icons.directions_run_rounded;
  if (name.contains("yoga") || name.contains("stretch") || name.contains("pilates") || name.contains("roll") || name.contains("massage")) return Icons.self_improvement_rounded;
  return Icons.fitness_center_rounded;
}

// --- WIDGETS ---
class ProButton extends StatelessWidget {
  final String text; final VoidCallback onPressed; final bool isLoading; final Color? color;
  ProButton({required this.text, required this.onPressed, this.isLoading = false, this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: color == null ? LinearGradient(colors: [kColorPrimary, Color(0xFF3E5C76)]) : null, color: color, boxShadow: [if (color == null) BoxShadow(color: kColorPrimary.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))]),
      child: ElevatedButton(onPressed: isLoading ? null : onPressed, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: isLoading ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kColorBackground, strokeWidth: 2)) : Text(text, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: kColorBackground))),
    );
  }
}

// --- SCREEN 1: HOME ---
class HomeScreen extends StatefulWidget {
  @override _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final AIService _aiService = AIService();
  bool isLoading = false;
  bool isRecoveryMode = false;
  String selectedDifficulty = "Intermediate";
  final List<String> difficulties = ["Beginner", "Intermediate", "Advanced"];
  Timer? _hintTimer;
  int _hintIndex = 0;
  final List<String> _trainHints = ["e.g. 1 week tennis prep...", "e.g. Upper body with dumbbells...", "e.g. 20 min HIIT cardio...", "e.g. Leg day hypertrophy...", "e.g. Full body no equipment..."];
  final List<String> _recoverHints = ["e.g. Post-match tennis recovery...", "e.g. Lower back pain relief...", "e.g. 15 min yoga flow...", "e.g. Full body foam rolling...", "e.g. Stiff neck stretches..."];

  @override 
  void initState() { 
    super.initState(); 
    _hintTimer = Timer.periodic(Duration(seconds: 3), (timer) { setState(() { _hintIndex++; }); });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkHomeTutorial());
  }
  @override void dispose() { _hintTimer?.cancel(); _controller.dispose(); super.dispose(); }

  void _checkHomeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool('seen_home_tutorial') ?? false;
    if (!seen) { Future.delayed(Duration(seconds: 1), () { if (mounted) _showHomeTutorialDialog(); }); }
  }

  void _showHomeTutorialDialog() {
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (ctx) => AlertDialog(
        backgroundColor: kColorCard, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: kColorPrimary, width: 1)), 
        title: Row(children: [Icon(Icons.touch_app_rounded, color: kColorPrimary), SizedBox(width: 10), Text("Quick Tour", style: GoogleFonts.outfit(color: kColorAccent, fontWeight: FontWeight.bold))]), 
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text("Find your tools in the top right:", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.7))), 
            SizedBox(height: 20), 
            Row(children: [Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: kColorBackground, shape: BoxShape.circle), child: Icon(Icons.person_rounded, color: kColorAccent)), SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Profile & Stats", style: GoogleFonts.outfit(color: kColorAccent, fontWeight: FontWeight.bold)), Text("Track your XP & Level", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.5), fontSize: 12))]))]), 
            SizedBox(height: 16), 
            Row(children: [Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: kColorBackground, shape: BoxShape.circle), child: Icon(Icons.settings_rounded, color: kColorAccent)), SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Settings", style: GoogleFonts.outfit(color: kColorAccent, fontWeight: FontWeight.bold)), Text("Sign out & Preferences", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.5), fontSize: 12))]))]),
            SizedBox(height: 16),
            Row(children: [Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: kColorBackground, shape: BoxShape.circle), child: Icon(Icons.star_rounded, color: Color(0xFFF4D35E))), SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Saved Plans", style: GoogleFonts.outfit(color: kColorAccent, fontWeight: FontWeight.bold)), Text("Replay your favorites", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.5), fontSize: 12))]))]),
          ]
        ), 
        actions: [TextButton(child: Text("GOT IT", style: GoogleFonts.outfit(color: kColorPrimary, fontWeight: FontWeight.bold)), onPressed: () async { final prefs = await SharedPreferences.getInstance(); await prefs.setBool('seen_home_tutorial', true); Navigator.of(ctx).pop(); })]
      )
    );
  }

  void _generateWorkout() async {
    if (_controller.text.isEmpty) { _showError("Please describe your session first."); return; }
    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    String smartPrompt = "${_controller.text}. (Context: User wants a $selectedDifficulty ${isRecoveryMode ? 'recovery' : 'training'} session).";

    try {
      final data = await _aiService.generateWorkout(smartPrompt, selectedDifficulty, isRecoveryMode);
      setState(() => isLoading = false);
      if (data.isNotEmpty) {
        data['is_recovery'] = isRecoveryMode; 
        Navigator.push(context, MaterialPageRoute(builder: (context) => PlanScreen(planData: data)));
      } else _showError("AI returned no data. Try a different prompt.");
    } catch (e) { setState(() => isLoading = false); _showError("Error: Check Internet or API Key."); }
  }

  void _showError(String message) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent)); }
  void _useQuickAction(String prompt, bool recovery) { setState(() { isRecoveryMode = recovery; _controller.text = prompt; }); }

  @override
  Widget build(BuildContext context) {
    List<String> currentHints = isRecoveryMode ? _recoverHints : _trainHints;
    String activeHint = currentHints[_hintIndex % currentHints.length];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: false, // LOGO TO LEFT
        title: FittedBox(fit: BoxFit.scaleDown, child: Row(children: [Icon(Icons.fitness_center_rounded, color: kColorPrimary, size: 24), SizedBox(width: 8), Text("FLEX", style: GoogleFonts.outfit(fontSize: 22, letterSpacing: 3, fontWeight: FontWeight.bold, color: kColorAccent))])),
        actions: [
          IconButton(icon: Icon(Icons.person_rounded, color: kColorAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()))),
          IconButton(icon: Icon(Icons.settings_rounded, color: kColorAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()))),
          IconButton(icon: Icon(Icons.star_rounded, color: Color(0xFFF4D35E)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesScreen()))),
        ],
      ),
      body: Container(
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topRight, radius: 1.5, colors: [kColorCard, kColorBackground])),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 120),
              Text(isRecoveryMode ? "Recover Smart." : "Train Hard.", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: kColorAccent)),
              Text(isRecoveryMode ? "Get back in the game." : "Build your legacy.", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: kColorPrimary.withOpacity(0.6))),
              SizedBox(height: 30),
              Container(padding: EdgeInsets.all(4), decoration: BoxDecoration(color: kColorCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Row(children: [Expanded(child: _buildModeTab("TRAIN", !isRecoveryMode, kColorPrimary, () => setState(() => isRecoveryMode = false))), Expanded(child: _buildModeTab("RECOVER", isRecoveryMode, kColorAccent, () => setState(() => isRecoveryMode = true)))]),),
              SizedBox(height: 20),
              if (!isRecoveryMode) ...[Text("Intensity Level", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.5), fontSize: 12)), SizedBox(height: 8), Row(children: difficulties.map((level) => Expanded(child: GestureDetector(onTap: () => setState(() => selectedDifficulty = level), child: Container(margin: EdgeInsets.symmetric(horizontal: 4), padding: EdgeInsets.symmetric(vertical: 8), alignment: Alignment.center, decoration: BoxDecoration(color: selectedDifficulty == level ? kColorPrimary.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: selectedDifficulty == level ? kColorPrimary : Colors.white10)), child: Text(level, style: GoogleFonts.inter(fontSize: 12, fontWeight: selectedDifficulty == level ? FontWeight.bold : FontWeight.normal, color: selectedDifficulty == level ? kColorAccent : kColorAccent.withOpacity(0.5))))))).toList()), SizedBox(height: 20)],
              TextField(controller: _controller, style: TextStyle(color: kColorAccent), decoration: InputDecoration(hintText: activeHint, hintStyle: TextStyle(color: kColorAccent.withOpacity(0.3)), filled: true, fillColor: kColorCard, contentPadding: EdgeInsets.all(20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), prefixIcon: Icon(isRecoveryMode ? Icons.spa_rounded : Icons.fitness_center_rounded, color: kColorAccent.withOpacity(0.3)))),
              SizedBox(height: 30),
              ProButton(text: isRecoveryMode ? "GENERATE RECOVERY" : "GENERATE WORKOUT", isLoading: isLoading, onPressed: _generateWorkout, color: isRecoveryMode ? kColorAccent : null),
              SizedBox(height: 40),
              Text("Quick Actions", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: kColorAccent)),
              SizedBox(height: 15),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_buildQuickCard("🎾 Tennis Match", "Recover from 2hr match", true, Icons.sports_tennis), _buildQuickCard("💪 Leg Day", "Hypertrophy leg workout", false, Icons.accessibility_new_rounded), _buildQuickCard("🧘 Daily Mobility", "15 min full body flow", true, Icons.self_improvement), _buildQuickCard("🏃 Cardio Blast", "30 min HIIT run", false, Icons.directions_run)])),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildModeTab(String text, bool isActive, Color activeColor, VoidCallback onTap) => GestureDetector(onTap: onTap, child: AnimatedContainer(duration: Duration(milliseconds: 200), padding: EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isActive ? activeColor : Colors.transparent, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isActive ? kColorBackground : kColorAccent.withOpacity(0.5)))));
  Widget _buildQuickCard(String title, String prompt, bool recovery, IconData icon) => GestureDetector(onTap: () => _useQuickAction(prompt, recovery), child: Container(width: 140, margin: EdgeInsets.only(right: 12), padding: EdgeInsets.all(16), decoration: BoxDecoration(color: kColorCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: recovery ? kColorAccent : kColorPrimary, size: 28), SizedBox(height: 12), Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: kColorAccent)), SizedBox(height: 4), Text(prompt, style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.5), fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis)])));
}

// --- SETTINGS SCREEN ---
class SettingsScreen extends StatelessWidget {
  Future<void> _logout(BuildContext context) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    try { await googleSignIn.disconnect(); } catch (e) {} 
    await googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => AuthWrapper()), (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text("Settings", style: TextStyle(color: kColorAccent)), iconTheme: IconThemeData(color: kColorAccent)),
      body: Column(
        children: [
          Container(
            width: double.infinity, margin: EdgeInsets.all(20), padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: kColorCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("ACCOUNT", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.5), fontSize: 12, letterSpacing: 2)), SizedBox(height: 15), Text(user?.email ?? "No Email", style: GoogleFonts.outfit(color: kColorAccent, fontSize: 16))]),
          ),
          ListTile(leading: Icon(Icons.logout_rounded, color: Colors.redAccent), title: Text("Sign Out", style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)), onTap: () => _logout(context))
        ],
      ),
    );
  }
}

// --- PROFILE SCREEN ---
class ProfileScreen extends StatefulWidget { @override _ProfileScreenState createState() => _ProfileScreenState(); }
class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Athlete"; String? googlePhotoUrl; String? localImagePath; 
  List<DateTime> workoutDates = []; Map<int, int> weeklyXP = {0:0, 1:0, 2:0, 3:0, 4:0, 5:0, 6:0}; int totalDumbbells = 0; bool isLoading = true;

  @override void initState() { super.initState(); _loadData(); }
  
  void _loadData() async {
    final prefs = await SharedPreferences.getInstance(); final user = FirebaseAuth.instance.currentUser;
    String name = user?.displayName ?? prefs.getString('user_name') ?? "Athlete"; 
    String? googlePhoto = user?.photoURL; String? localPhoto = prefs.getString('user_local_image_path');
    int dumbbells = prefs.getInt('dumbbells') ?? 0; List<String> history = prefs.getStringList('history') ?? []; List<DateTime> dates = []; Map<int, int> weekly = {1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0};
    DateTime now = DateTime.now(); DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1)); startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    for (String item in history) { try { var data = jsonDecode(item); if (data['date'] != null) { DateTime date = DateTime.parse(data['date']); dates.add(date); if (date.isAfter(startOfWeek) || date.isAtSameMomentAs(startOfWeek)) { weekly[date.weekday] = (weekly[date.weekday] ?? 0) + ((data['earned'] as int?) ?? 0); } } } catch (e) {} }
    setState(() { userName = name; googlePhotoUrl = googlePhoto; localImagePath = localPhoto; workoutDates = dates; totalDumbbells = dumbbells; weeklyXP = weekly; isLoading = false; });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker(); final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) { final prefs = await SharedPreferences.getInstance(); await prefs.setString('user_local_image_path', image.path); setState(() { localImagePath = image.path; }); }
  }

  void _showEditProfileDialog() {
    TextEditingController nameController = TextEditingController(text: userName);
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: kColorCard, title: Text("Edit Profile", style: GoogleFonts.outfit(color: kColorAccent, fontWeight: FontWeight.bold)), content: Column(mainAxisSize: MainAxisSize.min, children: [GestureDetector(onTap: () { Navigator.pop(context); _pickImage(); }, child: CircleAvatar(radius: 40, backgroundColor: kColorPrimary, backgroundImage: localImagePath != null ? FileImage(File(localImagePath!)) : (googlePhotoUrl != null ? NetworkImage(googlePhotoUrl!) : null) as ImageProvider?, child: (localImagePath == null && googlePhotoUrl == null) ? Text(userName.isNotEmpty ? userName.substring(0,1).toUpperCase() : "A", style: GoogleFonts.outfit(fontSize: 30, color: kColorBackground)) : Icon(Icons.camera_alt, color: kColorBackground))), SizedBox(height: 10), Text("Tap icon to change photo", style: GoogleFonts.inter(fontSize: 10, color: kColorAccent.withOpacity(0.5))), SizedBox(height: 20), TextField(controller: nameController, style: TextStyle(color: kColorAccent), decoration: InputDecoration(labelText: "Display Name", labelStyle: TextStyle(color: kColorAccent.withOpacity(0.5)), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kColorPrimary))))]), actions: [TextButton(child: Text("CANCEL"), onPressed: () => Navigator.pop(context)), TextButton(child: Text("SAVE", style: TextStyle(color: kColorPrimary, fontWeight: FontWeight.bold)), onPressed: () async { if (nameController.text.isNotEmpty) { final prefs = await SharedPreferences.getInstance(); await prefs.setString('user_name', nameController.text); setState(() => userName = nameController.text); Navigator.pop(context); } })]));
  }
  
  @override Widget build(BuildContext context) {
    int level = (totalDumbbells / 500).floor() + 1; int currentLevelProgress = totalDumbbells % 500; double progressPercent = currentLevelProgress / 500.0;
    ImageProvider? profileImage; if (localImagePath != null) { profileImage = FileImage(File(localImagePath!)); } else if (googlePhotoUrl != null) { profileImage = NetworkImage(googlePhotoUrl!); }
    return Scaffold(
      appBar: AppBar(title: Text("Profile", style: TextStyle(color: kColorAccent)), iconTheme: IconThemeData(color: kColorAccent)), 
      body: isLoading ? Center(child: CircularProgressIndicator()) : SingleChildScrollView(padding: EdgeInsets.all(20), child: Column(children: [Container(padding: EdgeInsets.all(24), decoration: BoxDecoration(gradient: LinearGradient(colors: [kColorPrimary.withOpacity(0.2), kColorCard]), borderRadius: BorderRadius.circular(24), border: Border.all(color: kColorPrimary.withOpacity(0.3))), child: Column(children: [GestureDetector(onTap: _showEditProfileDialog, child: Stack(children: [CircleAvatar(radius: 45, backgroundColor: kColorPrimary, backgroundImage: profileImage, child: profileImage == null ? Text(userName.isNotEmpty ? userName.substring(0,1).toUpperCase() : "A", style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: kColorBackground)) : null), Positioned(bottom: 0, right: 0, child: Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: kColorAccent, shape: BoxShape.circle, border: Border.all(color: kColorCard, width: 3)), child: Icon(Icons.edit, size: 12, color: kColorBackground)))])) , SizedBox(height: 16), Text(userName, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: kColorAccent)), Text("Level $level • $totalDumbbells Dumbbells", style: GoogleFonts.inter(fontSize: 14, color: kColorPrimary)), SizedBox(height: 20), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progressPercent, minHeight: 8, backgroundColor: kColorBackground, valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary))), SizedBox(height: 8), Text("$currentLevelProgress / 500 XP to Level ${level + 1}", style: GoogleFonts.inter(fontSize: 12, color: kColorAccent.withOpacity(0.5)))])), SizedBox(height: 30), Align(alignment: Alignment.centerLeft, child: Text("Weekly Progress (XP)", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: kColorAccent))), SizedBox(height: 15), Container(height: 180, padding: EdgeInsets.all(20), decoration: BoxDecoration(color: kColorCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end, children: ["M", "T", "W", "T", "F", "S", "S"].asMap().entries.map((entry) { int dayIdx = entry.key + 1; int xp = weeklyXP[dayIdx] ?? 0; double barHeight = (xp / 500.0).clamp(0.0, 1.0) * 80; bool isToday = DateTime.now().weekday == dayIdx; return Column(mainAxisAlignment: MainAxisAlignment.end, children: [if(xp > 0) Text("${xp}", style: TextStyle(fontSize: 10, color: kColorAccent.withOpacity(0.5))), SizedBox(height: 6), Container(width: 12, height: max(4, barHeight), decoration: BoxDecoration(color: isToday ? kColorAccent : kColorPrimary, borderRadius: BorderRadius.circular(4))), SizedBox(height: 8), Text(entry.value, style: GoogleFonts.inter(fontSize: 12, color: isToday ? kColorAccent : kColorAccent.withOpacity(0.5), fontWeight: isToday ? FontWeight.bold : FontWeight.normal))]); }).toList())), SizedBox(height: 30), Align(alignment: Alignment.centerLeft, child: Text("Consistency Heatmap", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: kColorAccent))), SizedBox(height: 15), _buildHeatmap()])));
  }
  Widget _buildHeatmap() => GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6), itemCount: 28, itemBuilder: (context, index) { DateTime cellDate = DateTime.now().subtract(Duration(days: 27 - index)); bool workedOut = workoutDates.any((d) => d.day == cellDate.day && d.month == cellDate.month); return Container(decoration: BoxDecoration(color: workedOut ? kColorPrimary : kColorCard, borderRadius: BorderRadius.circular(4), border: Border.all(color: workedOut ? kColorPrimary : Colors.white10)), child: Center(child: Text("${cellDate.day}", style: TextStyle(fontSize: 10, color: workedOut ? kColorBackground : kColorAccent.withOpacity(0.5), fontWeight: FontWeight.bold)))); });
}

// --- FAVORITES SCREEN ---
class FavoritesScreen extends StatefulWidget { @override _FavoritesScreenState createState() => _FavoritesScreenState(); }
class _FavoritesScreenState extends State<FavoritesScreen> { List<Map<String, dynamic>> favorites = []; bool isLoading = true; @override void initState() { super.initState(); _loadFavorites(); } void _loadFavorites() async { try { final prefs = await SharedPreferences.getInstance(); List<String> saved = prefs.getStringList('favorites') ?? []; List<Map<String, dynamic>> loadedData = []; for (String item in saved) { try { loadedData.add(jsonDecode(item)); } catch (e) {} } setState(() { favorites = loadedData; isLoading = false; }); } catch (e) { setState(() => isLoading = false); } } void _removeFavorite(int index) async { final prefs = await SharedPreferences.getInstance(); List<String> saved = prefs.getStringList('favorites') ?? []; if (index < saved.length) { saved.removeAt(index); await prefs.setStringList('favorites', saved); setState(() => favorites.removeAt(index)); } } void _confirmDelete(int index) { showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: kColorCard, title: Text("Delete Plan?", style: GoogleFonts.outfit(color: kColorAccent, fontWeight: FontWeight.bold)), content: Text("Remove this workout from your favorites?", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.7))), actions: [TextButton(child: Text("Cancel"), onPressed: () => Navigator.of(ctx).pop()), TextButton(child: Text("Delete", style: TextStyle(color: Colors.redAccent)), onPressed: () { Navigator.of(ctx).pop(); _removeFavorite(index); })])); } @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: Text("Saved Plans", style: TextStyle(color: kColorAccent)), iconTheme: IconThemeData(color: kColorAccent)), body: isLoading ? Center(child: CircularProgressIndicator()) : favorites.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bookmark_border_rounded, size: 60, color: kColorAccent.withOpacity(0.1)), SizedBox(height: 16), Text("No saved plans.", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.5)))])) : ListView.builder(padding: EdgeInsets.all(16), itemCount: favorites.length, itemBuilder: (context, index) { final plan = favorites[index]; String displayName = plan['plan_name'] ?? plan['title'] ?? "Unknown Plan"; List schedule = (plan['schedule'] is List) ? plan['schedule'] : []; if (schedule.isEmpty && plan['exercises'] != null) schedule = [1]; return Container(margin: EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: kColorCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: ListTile(contentPadding: EdgeInsets.all(16), leading: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: kColorPrimary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.star_rounded, color: kColorPrimary, size: 24)), title: Text(displayName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: kColorAccent)), subtitle: Text("${schedule.length} Day Schedule", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.5))), trailing: Icon(Icons.chevron_right_rounded, color: kColorAccent.withOpacity(0.5)), onTap: () { if (plan['schedule'] != null) Navigator.push(context, MaterialPageRoute(builder: (context) => PlanScreen(planData: plan))); else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Old data format."))); }, onLongPress: () => _confirmDelete(index))); })); } }

// --- PLAN OVERVIEW SCREEN ---
class PlanScreen extends StatefulWidget { final Map<String, dynamic> planData; PlanScreen({required this.planData}); @override _PlanScreenState createState() => _PlanScreenState(); }
class _PlanScreenState extends State<PlanScreen> {
  bool isFavorite = false; @override void initState() { super.initState(); _checkFavoriteStatus(); }
  void _checkFavoriteStatus() async { final prefs = await SharedPreferences.getInstance(); List<String> saved = prefs.getStringList('favorites') ?? []; setState(() => isFavorite = saved.contains(jsonEncode(widget.planData))); }
  void _toggleFavorite() async { final prefs = await SharedPreferences.getInstance(); List<String> saved = prefs.getStringList('favorites') ?? []; String currentJson = jsonEncode(widget.planData); if (isFavorite) saved.remove(currentJson); else if (!saved.contains(currentJson)) saved.add(currentJson); await prefs.setStringList('favorites', saved); setState(() => isFavorite = !isFavorite); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isFavorite ? "Saved" : "Removed"))); }
  @override Widget build(BuildContext context) {
    List schedule = (widget.planData['schedule'] is List) ? widget.planData['schedule'] : []; String planName = widget.planData['plan_name'] ?? "Workout Plan"; int xpReward = widget.planData['xp_reward'] ?? 100;
    bool isRecovery = widget.planData['is_recovery'] ?? false;
    return Scaffold(appBar: AppBar(title: Text(planName, style: TextStyle(color: kColorAccent)), iconTheme: IconThemeData(color: kColorAccent), actions: [IconButton(icon: Icon(isFavorite ? Icons.star_rounded : Icons.star_border_rounded, color: isFavorite ? Color(0xFFF4D35E) : Colors.white), onPressed: _toggleFavorite)]), body: Column(children: [Container(width: double.infinity, margin: EdgeInsets.all(16), padding: EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [kColorPrimary.withOpacity(0.2), Colors.transparent]), borderRadius: BorderRadius.circular(20), border: Border.all(color: kColorPrimary.withOpacity(0.3))), child: Row(children: [Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: kColorPrimary, shape: BoxShape.circle), child: Icon(Icons.emoji_events_rounded, color: kColorBackground, size: 20)), SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Reward", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.5), fontSize: 12)), Text("$xpReward Dumbbells", style: GoogleFonts.outfit(color: kColorAccent, fontSize: 18, fontWeight: FontWeight.bold))])])), Expanded(child: schedule.isEmpty ? Center(child: Text("No data", style: TextStyle(color: Colors.white24))) : ListView.builder(padding: EdgeInsets.symmetric(horizontal: 16), itemCount: schedule.length, itemBuilder: (context, index) { final day = schedule[index]; List exercises = day['exercises'] ?? []; bool isRestDay = exercises.isEmpty; return GestureDetector(onTap: isRestDay ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => ActiveSessionScreen(dayTitle: day['day_name'], exercises: exercises, xpReward: (xpReward / schedule.length).round(), isRecovery: isRecovery))), child: Container(margin: EdgeInsets.only(bottom: 12), padding: EdgeInsets.all(20), decoration: BoxDecoration(color: kColorCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: Row(children: [Container(width: 50, height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: isRestDay ? kColorAccent.withOpacity(0.1) : kColorPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text("${index + 1}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isRestDay ? kColorAccent : kColorPrimary, fontSize: 20))), SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(day['day_name'] ?? "Day ${index + 1}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: kColorAccent)), SizedBox(height: 4), Text(day['focus'] ?? "General", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.5), fontSize: 14))])), Icon(isRestDay ? Icons.spa_rounded : Icons.chevron_right_rounded, color: kColorAccent.withOpacity(0.5))]))); }))]));
  }
}

// --- ACTIVE SESSION SCREEN (WITH DUMBBELL EXPLOSION) ---
class ActiveSessionScreen extends StatefulWidget {
  final String dayTitle; final List exercises; final int xpReward; final bool isRecovery;
  ActiveSessionScreen({required this.dayTitle, required this.exercises, required this.xpReward, required this.isRecovery});
  @override _ActiveSessionScreenState createState() => _ActiveSessionScreenState();
}
class _ActiveSessionScreenState extends State<ActiveSessionScreen> with TickerProviderStateMixin {
  Map<int, Set<int>> completedSets = {};
  bool _celebrating = false;
  late AnimationController _animController;
  List<DumbbellParticle> _particles = [];
  
  @override void initState() { 
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(seconds: 3));
    _animController.addListener(() { setState(() {}); });
  }
  @override void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _launchMusic() async { String query = widget.isRecovery ? "calm relaxing music" : "upbeat workout music"; final Uri spotifyUrl = Uri.parse("spotify:search:$query"); try { if (await canLaunchUrl(spotifyUrl)) await launchUrl(spotifyUrl); } catch (e) { print(e); } }
  void _openExerciseDemo(String exerciseName) async { final query = Uri.encodeComponent("how to do $exerciseName"); final url = Uri.parse("https://www.youtube.com/results?search_query=$query"); if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication); }

  void _finishSession() async {
    _particles = List.generate(40, (index) => DumbbellParticle());
    setState(() => _celebrating = true);
    _animController.forward();
    final prefs = await SharedPreferences.getInstance(); 
    await prefs.setInt('dumbbells', (prefs.getInt('dumbbells') ?? 0) + widget.xpReward); 
    List<String> history = prefs.getStringList('history') ?? []; 
    history.add(jsonEncode({"title": widget.dayTitle, "date": DateTime.now().toIso8601String(), "earned": widget.xpReward})); 
    await prefs.setStringList('history', history); 
    Future.delayed(Duration(seconds: 3), () { Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => HomeScreen()), (Route<dynamic> route) => false); });
  }

  void _startRestTimer(int duration) { showModalBottomSheet(context: context, isDismissible: false, backgroundColor: kColorCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => RestTimerSheet(duration: duration)); }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.dayTitle, style: TextStyle(color: kColorAccent)), iconTheme: IconThemeData(color: kColorAccent), actions: [Center(child: Text("+${widget.xpReward} ", style: GoogleFonts.outfit(color: Color(0xFFF4D35E), fontWeight: FontWeight.bold))), Center(child: Icon(Icons.fitness_center_rounded, size: 16, color: Color(0xFFF4D35E))), SizedBox(width: 16), IconButton(icon: Icon(Icons.music_note_rounded, color: kColorAccent), onPressed: _launchMusic)]),
      body: Stack(
        children: [
          Column(
            children: [
              Container(width: double.infinity, padding: EdgeInsets.all(12), margin: EdgeInsets.fromLTRB(16, 16, 16, 0), decoration: BoxDecoration(color: kColorPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: kColorPrimary.withOpacity(0.3))), child: Row(children: [Icon(Icons.lightbulb_rounded, color: kColorPrimary, size: 20), SizedBox(width: 10), Expanded(child: Text("Smart Tip: If you completed your last session easily, aim to increase weights by 5% today.", style: GoogleFonts.inter(fontSize: 12, color: kColorAccent.withOpacity(0.8))))])),
              Expanded(child: ListView.builder(padding: EdgeInsets.all(16), itemCount: widget.exercises.length, itemBuilder: (context, index) { final ex = widget.exercises[index]; final int totalSets = ex['sets'] is int ? ex['sets'] : int.tryParse(ex['sets'].toString()) ?? 3; bool isExerciseComplete = (completedSets[index]?.length ?? 0) == totalSets; IconData exerciseIcon = _getExerciseIcon(ex['name']); return AnimatedContainer(duration: Duration(milliseconds: 300), margin: EdgeInsets.only(bottom: 16), padding: EdgeInsets.all(20), decoration: BoxDecoration(color: isExerciseComplete ? kColorAccent.withOpacity(0.05) : kColorCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: isExerciseComplete ? kColorAccent : Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: isExerciseComplete ? kColorAccent.withOpacity(0.2) : kColorPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(exerciseIcon, color: isExerciseComplete ? kColorAccent : kColorPrimary, size: 24)), SizedBox(width: 16), Expanded(child: InkWell(onTap: () => _openExerciseDemo(ex['name']), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(ex['name'], style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, decorationColor: kColorPrimary, color: kColorAccent)), Text("${ex['reps']} Reps • ${ex['rest_sec']}s Rest", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.5), fontSize: 13))])), Icon(Icons.play_circle_filled_rounded, color: kColorPrimary, size: 24)])))]), SizedBox(height: 16), Wrap(spacing: 12, runSpacing: 12, children: List.generate(totalSets, (setIndex) { int setNumber = setIndex + 1; bool isSetDone = completedSets[index]?.contains(setNumber) ?? false; return GestureDetector(onTap: () { setState(() { if (completedSets[index] == null) completedSets[index] = {}; if (isSetDone) completedSets[index]!.remove(setNumber); else { completedSets[index]!.add(setNumber); if (completedSets[index]!.length < totalSets) _startRestTimer(ex['rest_sec'] ?? 60); } }); }, child: AnimatedContainer(duration: Duration(milliseconds: 200), width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: isSetDone ? kColorAccent : Colors.transparent, border: Border.all(color: isSetDone ? kColorAccent : Colors.white24), shape: BoxShape.circle), child: Text("$setNumber", style: GoogleFonts.outfit(color: isSetDone ? kColorBackground : kColorAccent, fontWeight: FontWeight.bold)))); }))])); })),
              Padding(padding: EdgeInsets.all(24), child: ProButton(text: "COMPLETE WORKOUT", color: kColorAccent, onPressed: _celebrating ? () {} : _finishSession))
            ],
          ),
          if (_celebrating)
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    ..._particles.map((p) { p.update(); return Positioned(left: p.x, bottom: p.y, child: Transform.rotate(angle: p.angle, child: Icon(Icons.fitness_center, size: p.size, color: p.color))); }).toList(),
                    Center(child: Container(padding: EdgeInsets.all(30), decoration: BoxDecoration(color: kColorBackground.withOpacity(0.9), borderRadius: BorderRadius.circular(20), border: Border.all(color: kColorAccent)), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("YOU EARNED", style: GoogleFonts.outfit(color: kColorAccent, fontSize: 20)), Text("${widget.xpReward}", style: GoogleFonts.outfit(color: kColorPrimary, fontSize: 60, fontWeight: FontWeight.bold)), Text("DUMBBELLS", style: GoogleFonts.outfit(color: kColorAccent, fontSize: 20))]))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- DUMBBELL PARTICLE LOGIC ---
class DumbbellParticle {
  double x = Random().nextDouble() * 400; double y = -50; double velocityY = 15 + Random().nextDouble() * 10; double velocityX = (Random().nextDouble() - 0.5) * 5; double angle = Random().nextDouble() * pi; double rotationSpeed = (Random().nextDouble() - 0.5) * 0.2; double size = 20 + Random().nextDouble() * 20;
  Color color = [kColorPrimary, kColorAccent, Colors.white, Color(0xFFF4D35E)][Random().nextInt(4)];
  void update() { y += velocityY; x += velocityX; velocityY -= 0.8; angle += rotationSpeed; }
}

class RestTimerSheet extends StatefulWidget { final int duration; RestTimerSheet({required this.duration}); @override _RestTimerSheetState createState() => _RestTimerSheetState(); }
class _RestTimerSheetState extends State<RestTimerSheet> { late int timeLeft; Timer? _timer; @override void initState() { super.initState(); timeLeft = widget.duration; startTimer(); } void startTimer() { _timer = Timer.periodic(Duration(seconds: 1), (timer) { if (timeLeft > 0) setState(() => timeLeft--); else { _timer?.cancel(); if (mounted) Navigator.pop(context); } }); } @override void dispose() { _timer?.cancel(); super.dispose(); } @override Widget build(BuildContext context) { return SafeArea(child: Container(padding: EdgeInsets.all(30), width: double.infinity, child: Column(mainAxisSize: MainAxisSize.min, children: [Text("REST TIME", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white24, letterSpacing: 2)), SizedBox(height: 20), Text("$timeLeft", style: GoogleFonts.outfit(fontSize: 100, fontWeight: FontWeight.bold, color: kColorPrimary)), SizedBox(height: 30), TextButton(onPressed: () { _timer?.cancel(); Navigator.pop(context); }, child: Text("SKIP REST", style: TextStyle(color: Colors.white54, letterSpacing: 1)))]))); } }

class SplashScreen extends StatefulWidget {
  @override _SplashScreenState createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override void initState() { super.initState(); Timer(Duration(seconds: 3), () { Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (_, __, ___) => HomeScreen(), transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child), transitionDuration: Duration(milliseconds: 800))); }); }
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: kColorBackground, body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.fitness_center_rounded, size: 100, color: kColorPrimary), SizedBox(height: 30), Text("FLEX", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4, color: kColorPrimary))]))); }
}