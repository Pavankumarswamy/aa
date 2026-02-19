import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smartlearn/models/game_model.dart';

class AIService {
  final Dio _dio = Dio();
  final String _baseUrl = "https://integrate.api.nvidia.com/v1";
  final String? _apiKey = dotenv.env['NV_API_KEY'];

  Future<List<Question>> generateQuestions({
    required String courseName,
    required String conceptName,
    required String gameType,
    int count = 5,
  }) async {
    if (_apiKey == null) {
      throw Exception('API Key not found in environment');
    }

    String prompt =
        """
    You are a professional educational content creator and game designer.
    Generate $count questions for a course named '$courseName' on the specific concept of '$conceptName'.
    The game type is '$gameType'.

    STRICT GUIDELINES:
    1. EXTREME CONCİSENESS: Keep everything very short. Questions < 12 words, Options < 4 words, Explanations < 15 words.
    2. JSON ONLY: Your entire response must be a valid JSON array. Do not include any text before or after the JSON.
    3. NO PLACEHOLDERS: Generate real, high-quality educational content.
    
    STRUCTURE BASED ON GAME TYPE ($gameType):

    - If 'quest_learn', 'brain_battle', 'time_rush', 'mastery_boss', 'mystery_mind':
      {
        "question": "Clear question?",
        "options": ["A", "B", "C", "D"],
        "correctAnswer": 0, // Index (0-3)
        "explanation": "Why it's correct."
      }

    - If 'level_up' (True/False):
      {
        "question": "Fact-based statement?",
        "options": ["True", "False"],
        "correctAnswer": 0, // 0 for True, 1 for False
        "explanation": "Brief verification."
      }

    - If 'puzzle_path' (Word Connect):
      {
        "question": "Definition/Hint for a hidden word.",
        "options": ["L", "O", "V", "E"], // Individual letters (scrambled)
        "correctAnswer": "LOVE", // The full word
        "explanation": "Brief context."
      }

    - If 'concept_evo' (Matching):
      {
        "question": "Match the pairs:",
        "options": ["Capital|Country", "Paris|France", "Berlin|Germany"],
        "correctAnswer": 0, // Always 0 for this type
        "explanation": "Quick summary."
      }

    - If 'build_learn' (Fill in Blanks):
      {
        "question": "Sentence with a ____ blank.",
        "options": ["missingWord"],
        "correctAnswer": 0,
        "explanation": "Full completed sentence."
      }

    - If 'skill_tree' (Ordering/Sequencing):
      {
        "question": "Order these steps:",
        "options": ["Step 1", "Step 2", "Step 3"],
        "correctAnswer": 0,
        "explanation": "Correct sequence explanation."
      }

    Generate exactly $count objects in a JSON array.
    """;

    try {
      final response = await _dio.post(
        "$_baseUrl/chat/completions",
        options: Options(
          headers: {
            "Authorization": "Bearer $_apiKey",
            "Content-Type": "application/json",
          },
        ),
        data: {
          "model": "meta/llama-3.1-405b-instruct",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a professional educational content generator. You only output valid JSON arrays.",
            },
            {"role": "user", "content": prompt},
          ],
          "temperature": 0.1,
          "top_p": 1,
          "max_tokens": 1024,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      // Extract JSON if AI surrounds it with markdown
      final jsonString = _extractJson(content);
      final List<dynamic> data = json.decode(jsonString);

      return data.map((q) => Question.fromMap(q)).toList();
    } catch (e) {
      print('AI Gen Error: $e');
      throw Exception('Failed to generate content: $e');
    }
  }

  String _extractJson(String content) {
    if (content.contains('```json')) {
      return content.split('```json')[1].split('```')[0].trim();
    } else if (content.contains('```')) {
      return content.split('```')[1].split('```')[0].trim();
    }
    return content.trim();
  }
}
