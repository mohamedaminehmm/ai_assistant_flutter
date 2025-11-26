// lib/models/intent_classifier.dart - FIXED VERSION
import 'dart:convert';
import 'package:flutter/services.dart';

class IntentClassifier {
  Map<String, dynamic>? config;
  List<String> labels = [];

  Future<void> loadModel() async {
    try {
      print('🔄 Loading enhanced classifier...');

      // Load configuration
      final configString =
          await rootBundle.loadString('assets/models/mobile_config.json');
      config = json.decode(configString);

      final labelsList = config?['labels'] as List<dynamic>?;
      labels = labelsList?.cast<String>() ?? [];

      print('✅ Enhanced classifier loaded successfully');
      print('📊 Available labels: $labels');
    } catch (e) {
      print('❌ Error loading classifier: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> predict(String text) async {
    try {
      print('🔍 Predicting intent for: "$text"');

      // Convert to lowercase and clean the text
      final cleanText = text.toLowerCase().trim();
      final words = cleanText.split(RegExp(r'\s+'));

      // Enhanced classification with better pattern matching
      final prediction = _enhancedPredict(cleanText, words);

      print(
          '🎯 Prediction: ${prediction['intent']} (${(prediction['confidence'] * 100).toStringAsFixed(1)}%)');

      return prediction;
    } catch (e) {
      print('❌ Prediction error: $e');
      return {
        'intent': 'error',
        'confidence': 0.0,
        'all_predictions': {},
        'input_text': text,
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _enhancedPredict(String fullText, List<String> words) {
    // Score for each intent category
    final scores = {
      'app': 0.0,
      'call': 0.0,
      'search': 0.0,
      'note': 0.0,
      'reminder': 0.0,
    };

    // Enhanced keyword patterns with weights
    final patterns = {
      'app': {
        'keywords': ['open', 'launch', 'start', 'run'],
        'apps': [
          'youtube',
          'spotify',
          'browser',
          'camera',
          'messages',
          'phone',
          'settings',
          'gallery',
          'calendar',
          'app',
          'application'
        ],
        'weight': 2.0,
      },
      'call': {
        'keywords': ['call', 'dial', 'ring', 'phone', 'contact'],
        'people': [
          'mom',
          'dad',
          'emergency',
          'home',
          'office',
          'wife',
          'husband',
          'brother',
          'sister',
          'john',
          'smith'
        ],
        'weight': 2.0,
      },
      'search': {
        'keywords': [
          'search',
          'find',
          'look',
          'google',
          'what',
          'who',
          'when',
          'where',
          'why',
          'how',
          'which',
          'information',
          'details',
          'about'
        ],
        'topics': [
          'weather',
          'news',
          'restaurants',
          'python',
          'web',
          'online',
          'discover',
          'barry',
          'allen',
          'america',
          'definition',
          'meaning'
        ],
        'weight': 1.5,
      },
      'note': {
        'keywords': [
          'write',
          'take',
          'create',
          'make',
          'note',
          'memo',
          'jot',
          'record',
          'remember'
        ],
        'actions': ['down', 'list', 'thoughts', 'message', 'idea'],
        'weight': 2.0,
      },
      'reminder': {
        'keywords': [
          'set',
          'remind',
          'alert',
          'schedule',
          'alarm',
          'timer',
          'wake',
          'notify'
        ],
        'nouns': [
          'reminder',
          'appointment',
          'meeting',
          'tomorrow',
          'today',
          'week',
          'time'
        ],
        'weight': 2.0,
      },
    };

    // Calculate scores based on patterns
    patterns.forEach((intent, pattern) {
      final keywords = (pattern['keywords'] as List<dynamic>).cast<String>();
      final specificWords = _getSpecificWords(pattern);
      final weight = pattern['weight'] as double;

      double intentScore = 0.0;

      // Check for keywords
      for (final word in words) {
        if (keywords.contains(word)) {
          intentScore += weight;
        }
        if (specificWords.contains(word)) {
          intentScore += weight * 0.5;
        }
      }

      // Special cases for search intent
      if (intent == 'search') {
        // Questions (who, what, when, where, why, how)
        if (fullText.startsWith('who') ||
            fullText.startsWith('what') ||
            fullText.startsWith('when') ||
            fullText.startsWith('where') ||
            fullText.startsWith('why') ||
            fullText.startsWith('how') ||
            fullText.startsWith('which')) {
          intentScore += 3.0;
        }

        // Information-seeking patterns
        if (fullText.contains('who is') ||
            fullText.contains('what is') ||
            fullText.contains('who discovered') ||
            fullText.contains('who created') ||
            fullText.contains('check who') ||
            fullText.contains('find out who')) {
          intentScore += 2.0;
        }

        // General knowledge queries
        if (fullText.contains('discover') ||
            fullText.contains('invent') ||
            fullText.contains('create') ||
            fullText.contains('history of') ||
            fullText.contains('about')) {
          intentScore += 1.5;
        }
      }

      scores[intent] = intentScore;
    });

    // Normalize scores to probabilities
    final total = scores.values.reduce((a, b) => a + b);
    final allPredictions = <String, double>{};

    String bestIntent = 'unknown';
    double bestScore = 0.0;

    scores.forEach((intent, score) {
      final probability = total > 0 ? score / total : 0.0;
      allPredictions[intent] = probability;

      if (probability > bestScore) {
        bestScore = probability;
        bestIntent = intent;
      }
    });

    // If confidence is low, use fallback logic
    if (bestScore < 0.3) {
      return _smartFallback(fullText, words, allPredictions);
    }

    return {
      'intent': bestIntent,
      'confidence': bestScore,
      'all_predictions': allPredictions,
      'input_text': fullText,
    };
  }

  // Helper method to safely get specific words
  List<String> _getSpecificWords(Map<String, dynamic> pattern) {
    if (pattern['nouns'] != null) {
      return (pattern['nouns'] as List<dynamic>).cast<String>();
    } else if (pattern['apps'] != null) {
      return (pattern['apps'] as List<dynamic>).cast<String>();
    } else if (pattern['people'] != null) {
      return (pattern['people'] as List<dynamic>).cast<String>();
    } else if (pattern['topics'] != null) {
      return (pattern['topics'] as List<dynamic>).cast<String>();
    } else if (pattern['actions'] != null) {
      return (pattern['actions'] as List<dynamic>).cast<String>();
    }
    return [];
  }

  Map<String, dynamic> _smartFallback(
      String fullText, List<String> words, Map<String, double> allPredictions) {
    // Smart fallback based on content analysis

    // Check for question patterns
    if (fullText.contains('?') ||
        fullText.startsWith('who') ||
        fullText.startsWith('what') ||
        fullText.startsWith('when') ||
        fullText.startsWith('where') ||
        fullText.startsWith('why') ||
        fullText.startsWith('how') ||
        fullText.contains('who is') ||
        fullText.contains('what is') ||
        fullText.contains('discover') ||
        fullText.contains('check') ||
        fullText.contains('find out')) {
      allPredictions['search'] = 0.9;
      return {
        'intent': 'search',
        'confidence': 0.9,
        'all_predictions': allPredictions,
        'input_text': fullText,
        'note': 'Detected as information query',
      };
    }

    // Check for app opening patterns
    if (words.contains('open') ||
        words.contains('launch') ||
        words.contains('start')) {
      allPredictions['app'] = 0.8;
      return {
        'intent': 'app',
        'confidence': 0.8,
        'all_predictions': allPredictions,
        'input_text': fullText,
      };
    }

    // Check for calling patterns
    if (words.contains('call') ||
        words.contains('phone') ||
        words.contains('dial')) {
      allPredictions['call'] = 0.8;
      return {
        'intent': 'call',
        'confidence': 0.8,
        'all_predictions': allPredictions,
        'input_text': fullText,
      };
    }

    // Check for note-taking patterns
    if (words.contains('write') ||
        words.contains('note') ||
        words.contains('remember')) {
      allPredictions['note'] = 0.8;
      return {
        'intent': 'note',
        'confidence': 0.8,
        'all_predictions': allPredictions,
        'input_text': fullText,
      };
    }

    // Check for reminder patterns
    if (words.contains('remind') ||
        words.contains('alarm') ||
        words.contains('timer')) {
      allPredictions['reminder'] = 0.8;
      return {
        'intent': 'reminder',
        'confidence': 0.8,
        'all_predictions': allPredictions,
        'input_text': fullText,
      };
    }

    // Default to search for general queries
    allPredictions['search'] = 0.7;
    return {
      'intent': 'search',
      'confidence': 0.7,
      'all_predictions': allPredictions,
      'input_text': fullText,
      'note': 'Defaulted to search for general query',
    };
  }

  void dispose() {
    // Nothing to dispose for pure Dart implementation
  }
}
