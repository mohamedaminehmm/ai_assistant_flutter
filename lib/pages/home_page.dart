// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:assistant/models/intent_classifier.dart';
import 'package:assistant/services/command_executor.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final IntentClassifier _classifier = IntentClassifier();
  final CommandExecutor _executor = CommandExecutor();
  final TextEditingController _textController = TextEditingController();
  Map<String, dynamic>? _lastPrediction;
  Map<String, dynamic>? _lastExecution;
  bool _isLoading = false;
  bool _isExecuting = false;
  String _status = 'Loading model...';

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      await _classifier.loadModel();
      setState(() {
        _status = 'Model ready! Type a command below.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading model: $e';
      });
    }
  }

  Future<void> _predictAndExecute() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    print('🚀 STARTING PREDICTION AND EXECUTION: "$text"');

    setState(() {
      _isLoading = true;
      _isExecuting = false;
      _status = 'Classifying intent...';
      _lastExecution = null;
    });

    try {
      // Step 1: Predict intent
      print('🔍 Predicting intent...');
      final prediction = await _classifier.predict(text);
      print('✅ Intent predicted: ${prediction['intent']}');

      setState(() {
        _lastPrediction = prediction;
        _isLoading = false;
        _isExecuting = true;
        _status = 'Executing command...';
      });

      // Step 2: Execute the command
      print('🔄 EXECUTING COMMAND: ${prediction['intent']} - "$text"');
      final executionResult = await _executor.executeCommand(
        prediction['intent'],
        text,
        context,
      );

      print(
          '🎯 EXECUTION RESULT: ${executionResult['success']} - ${executionResult['message']}');

      setState(() {
        _lastExecution = executionResult;
        _isExecuting = false;
        _status = executionResult['success'] == true
            ? 'Command executed successfully!'
            : 'Command failed';
      });
    } catch (e) {
      print('❌ ERROR: $e');
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
        _isExecuting = false;
      });
    }
  }

  void _clearInput() {
    _textController.clear();
    setState(() {
      _lastPrediction = null;
      _lastExecution = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_lastPrediction != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearInput,
              tooltip: 'Clear',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              _buildStatusCard(),

              const SizedBox(height: 20),

              // Input Section
              _buildInputSection(),

              const SizedBox(height: 20),

              // Results Section
              if (_lastPrediction != null) _buildPredictionCard(),

              if (_lastExecution != null) _buildExecutionCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor = Colors.blue;
    IconData statusIcon = Icons.info;

    if (_isLoading) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_top;
    } else if (_isExecuting) {
      statusColor = Colors.purple;
      statusIcon = Icons.play_arrow;
    } else if (_lastExecution != null) {
      statusColor =
          _lastExecution!['success'] == true ? Colors.green : Colors.red;
      statusIcon =
          _lastExecution!['success'] == true ? Icons.check_circle : Icons.error;
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isLoading || _isExecuting) const SizedBox(height: 8),
                  if (_isLoading || _isExecuting)
                    const LinearProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter a command:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: 'e.g., "open youtube", "call mom", "search weather"',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              onPressed: _predictAndExecute,
            ),
          ),
          onSubmitted: (_) => _predictAndExecute(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: (_isLoading || _isExecuting) ? null : _predictAndExecute,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: (_isLoading || _isExecuting)
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text(
                  'Execute Command',
                  style: TextStyle(fontSize: 16),
                ),
        ),
      ],
    );
  }

  Widget _buildPredictionCard() {
    final intent = _lastPrediction!['intent'] as String;
    final confidence = _lastPrediction!['confidence'] as double;
    final inputText = _lastPrediction!['input_text'] as String;
    final allPredictions =
        _lastPrediction!['all_predictions'] as Map<String, double>;

    Color getIntentColor(String intent) {
      switch (intent) {
        case 'app':
          return Colors.blue;
        case 'call':
          return Colors.green;
        case 'search':
          return Colors.orange;
        case 'note':
          return Colors.purple;
        case 'reminder':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: getIntentColor(intent)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Command: "$inputText"',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Detected: ${intent.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: getIntentColor(intent),
                        ),
                      ),
                      Text(
                        'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionCard() {
    final success = _lastExecution!['success'] as bool;
    final message = _lastExecution!['message'] as String;
    final action = _lastExecution!['action_taken'] as String;

    return Card(
      elevation: 3,
      color: success ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    success ? 'Command Executed' : 'Execution Failed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: success ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            if (action != 'none') ...[
              const SizedBox(height: 8),
              Text(
                'Action: $action',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            // Show additional info if available
            if (_lastExecution!['app_name'] != null)
              Text(
                'App: ${_lastExecution!['app_name']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if (_lastExecution!['query'] != null)
              Text(
                'Query: ${_lastExecution!['query']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classifier.dispose();
    _textController.dispose();
    super.dispose();
  }
}
