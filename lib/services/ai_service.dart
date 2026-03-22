import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../env/api_key.dart';

class AIService {
  // ---------------------------------------------
  // 👇 API KEY READ FROM IGNORED FILE
  static const apiKey = Env.geminiApiKey;
  // ---------------------------------------------
  
  final model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey);

  Future<Map<String, dynamic>> generateWorkout(String userPrompt, String difficulty, bool isRecoveryMode) async {
    
    // 1. Define the "Persona" based on Mode
    String systemInstruction;
    if (isRecoveryMode) {
      systemInstruction = '''
        You are an elite Sports Physiotherapist and Recovery Specialist.
        The user has just finished a match or intense activity.
        GOAL: Create a recovery session (Stretching, Mobility, Foam Rolling, Mental Reset).
        INTENSITY: Low. Focus on flushing lactic acid and preventing injury.
      ''';
    } else {
      systemInstruction = '''
        You are an elite Strength & Conditioning Coach.
        GOAL: Create a workout plan based on the user's request.
        DIFFICULTY LEVEL: $difficulty. Adjust sets, reps, and complexity accordingly.
        - Beginner: Basic movements, lower volume.
        - Intermediate: Standard hypertrophy/strength protocols.
        - Advanced: High volume, supersets, complex movements.
      ''';
    }

    final prompt = '''
      $systemInstruction
      
      User Request: "$userPrompt"
      
      INTELLIGENT ANALYSIS:
      1. Context: Detect sport or activity if mentioned.
      2. Equipment: Use standard gym gear unless user says "no equipment" or "dumbbells only".
      3. Schedule: If user asks for "1 week" or "split", create multiple days. Otherwise, 1 day.
      
      REQUIRED JSON STRUCTURE:
      {
        "plan_name": "Plan Name (e.g. 'Post-Match Flush' or 'Advanced Leg Day')",
        "xp_reward": 150, (Int 50-500)
        "schedule": [
          {
            "day_name": "Day 1",
            "focus": "Focus Area",
            "exercises": [
              { "name": "Exercise Name", "sets": 3, "reps": 12, "rest_sec": 60 }
            ]
          }
        ]
      }
      
      Return ONLY raw JSON.
    ''';

    final content = [Content.text(prompt)];

    try {
      final response = await model.generateContent(content);
      String? text = response.text;
      
      if (text == null) return {};

      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      Map<String, dynamic> data = jsonDecode(text);

      // Safety Layer
      if (!data.containsKey('schedule') && data.containsKey('exercises')) {
        return {
          "plan_name": data['title'] ?? "Session",
          "xp_reward": 100,
          "schedule": [
            {
              "day_name": "The Session",
              "focus": "General",
              "exercises": data['exercises']
            }
          ]
        };
      }
      return data;
    } catch (e) {
      print("AI Error: $e");
      return {};
    }
  }
}