import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

// --- NEW "MIDNIGHT & SAND" PALETTE (MATCHING MAIN.DART) ---
const Color kColorBackground = Color(0xFF0D1321); // Deepest Navy
const Color kColorCard = Color(0xFF1D2D44);       // Dark Navy
const Color kColorPrimary = Color(0xFF748CAB);    // Steel Blue
const Color kColorAccent = Color(0xFFF0EBD8);     // Sand/Beige

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;

  void _handleGoogleSignIn() async {
    setState(() => isLoading = true);
    try {
      await AuthService().signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: $e"), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [kColorCard, kColorBackground],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                Container(
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: kColorPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: kColorPrimary.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(Icons.fitness_center_rounded, size: 80, color: kColorPrimary),
                ),
                SizedBox(height: 30),
                Text("FLEX", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 5, color: kColorAccent)),
                Text("AI COACHING", style: GoogleFonts.inter(fontSize: 12, letterSpacing: 2, color: kColorPrimary)),
                Spacer(),
                if (isLoading)
                  CircularProgressIndicator(color: kColorPrimary)
                else
                  GestureDetector(
                    onTap: _handleGoogleSignIn,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: kColorPrimary, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Text("G", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: kColorPrimary, fontSize: 18))),
                          SizedBox(width: 15),
                          Text("Continue with Google", style: GoogleFonts.outfit(color: kColorBackground, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                Text("Train Smart. Recover Smarter.", style: GoogleFonts.inter(color: kColorAccent.withOpacity(0.5), fontSize: 12)),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}