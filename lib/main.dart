import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import 'database_helper.dart'; // Import the database helper

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Voice Leave Application',
      home: SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  String? _leaveType;
  String? _startDate;
  String? _endDate;
  String? _dayType;
  String? _reason;
  String? _remarks;
  bool? _isReadyToSubmit;
  String _errorMessage = "";
  bool _isListening = false;
  String _recognizedText = "";
  bool _isSubmitted = false;
  String? _summaryText;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: _statusListener,
      onError: _errorListener,
    );
    if (!available) {
      setState(() {
        _errorMessage = "Speech recognition is not available on this device.";
      });
    }
  }

  void _statusListener(String status) {
    setState(() {
      _isListening = status == "listening";
    });
  }

  void _errorListener(error) {
    setState(() {
      _errorMessage = "Error: ${error.errorMsg}";
      _isListening = false;
    });
  }

  void _resetLeaveApplication() {
    setState(() {
      _leaveType = null;
      _startDate = null;
      _endDate = null;
      _dayType = null;
      _reason = null;
      _remarks = null;
      _isReadyToSubmit = null;
      _isSubmitted = false;
      _errorMessage = "";
      _recognizedText = "";
      _summaryText = null;
    });
  }

  Future<void> _saveToDatabase() async {
    final leaveApplication = {
      'leaveType': _leaveType,
      'startDate': _startDate,
      'endDate': _endDate,
      'dayType': _dayType,
      'reason': _reason,
      'remarks': _remarks,
    };

    await DatabaseHelper.instance.insertLeaveApplication(leaveApplication);
    setState(() {
      _errorMessage = "Leave application submitted successfully!";
      _isSubmitted = true;
    });
    _showSummary();
    Future.delayed(const Duration(seconds: 3), () {
      _resetLeaveApplication();
    });
  }

  void _showSummary() {
    setState(() {
      _summaryText = '''
        Leave Summary:
        - Leave Type: $_leaveType
        - Date Range: $_startDate to $_endDate
        - Day Type: $_dayType
        - Reason: $_reason
        ${_remarks != null ? '- Remarks: $_remarks' : ''}
      ''';
    });
  }

  Widget _buildLeaveSummary() {
    return Text(
      _summaryText ?? '',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  void _processRecognitionResult(String recognized) {
    setState(() {
      _recognizedText = recognized;
    });

    if (_leaveType == null) {
      if (recognized.contains(RegExp(r'\bmedical leave\b', caseSensitive: false)) ||
          recognized.contains(RegExp(r'\bMC\b', caseSensitive: false))) {
        _leaveType = 'Medical Leave';
      } else if (recognized.contains(RegExp(r'\bconvocation leave\b', caseSensitive: false))) {
        _leaveType = 'Convocation Leave';
      } else if (recognized.contains(RegExp(r'\bemergency leave\b', caseSensitive: false))) {
        _leaveType = 'Emergency Leave';
      } else if (recognized.contains(RegExp(r'\bhospitalization leave\b', caseSensitive: false))) {
        _leaveType = 'Hospitalization Leave';
      } else if (recognized.contains(RegExp(r'\boutstation leave\b', caseSensitive: false))) {
        _leaveType = 'Outstation Leave';
      } else if (recognized.contains(RegExp(r'\bquarantine leave\b', caseSensitive: false))) {
        _leaveType = 'Quarantine Leave';
      } else if (recognized.contains(RegExp(r'\bunpaid leave\b', caseSensitive: false))) {
        _leaveType = 'Unpaid Leave';
      } else {
        setState(() {
          _errorMessage = "Please specify a valid leave type (e.g., medical leave, emergency leave).";
        });
        return;
      }
      setState(() {
        _errorMessage = "Leave type: $_leaveType.\nPlease specify the date range.";
      });
      return;
    }

    if (_startDate == null || _endDate == null) {
      if (recognized.contains(RegExp(r'\btoday\b', caseSensitive: false))) {
        _startDate = DateFormat('d MMMM').format(DateTime.now());
        _endDate = _startDate;
        setState(() {
          _errorMessage = "Date range: Today.\nPlease specify the day type (e.g., full day, 1st half, 2nd half).";
        });
        return;
      } else if (recognized.contains(RegExp(r'\btomorrow\b', caseSensitive: false))) {
        DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
        _startDate = DateFormat('d MMMM').format(tomorrow);
        _endDate = _startDate;
        setState(() {
          _errorMessage = "Date range: Tomorrow.\nPlease specify the day type (e.g., full day, 1st half, 2nd half).";
        });
        return;
      }

      String recognizedWithNumbers = recognized
          .replaceAll(RegExp(r'\bone\b', caseSensitive: false), '1')
          .replaceAll(RegExp(r'\btwo\b', caseSensitive: false), '2')
          .replaceAll(RegExp(r'\bthree\b', caseSensitive: false), '3');

      RegExp ordinalDateRegExp = RegExp(r'(\d{1,2})(st|nd|rd|th)\s\w+', caseSensitive: false);
      Match? dateMatch = ordinalDateRegExp.firstMatch(recognizedWithNumbers);
      if (dateMatch != null) {
        _startDate = dateMatch.group(0);
        _endDate = _startDate;
        setState(() {
          _errorMessage = "Date range: $_startDate.\nPlease specify the day type (e.g., full day, 1st half, 2nd half).";
        });
        return;
      }

      setState(() {
        _errorMessage = "Please provide a valid date range.";
      });
      return;
    }

    if (_dayType == null) {
      if (recognized.contains('full day')) {
        _dayType = 'Full Day';
      } else if (recognized.contains('first half') || recognized.contains('1st half')) {
        _dayType = '1st Half';
      } else if (recognized.contains('second half') || recognized.contains('2nd half')) {
        _dayType = '2nd Half';
      } else {
        setState(() {
          _errorMessage = "Specify the day type (e.g., full day, 1st half, or 2nd half).";
        });
        return;
      }
      setState(() {
        _errorMessage = "Day type: $_dayType.\nPlease pick others as reason.";
      });
      return;
    }

    if (_reason == null) {
      if (recognized.contains('other')) {
        _reason = 'Other';
        setState(() {
          _errorMessage = "Reason: Other.\nPlease provide additional remarks (e.g., because I need to attend a family event).";
        });
        return;
      } else {
        setState(() {
          _errorMessage = "Please choose 'Others' as the reason.";
        });
        return;
      }
    }

    if (_reason == 'Other' && _remarks == null) {
      if (recognized.contains('because')) {
        // Start capturing text after "because" for the remarks
        int index = recognized.toLowerCase().indexOf("because");
        if (index != -1) {
          String afterBecause = recognized.substring(index + "because".length).trim();
          _remarks = (_remarks ?? '') + ' ' + afterBecause; // Append each recognized segment
          setState(() {
            _errorMessage = "Remarks: $_remarks.\nAre you ready to submit the application? Say 'okay' or 'ready' to confirm.";
          });
        }
        return;
      } else {
        setState(() {
          _errorMessage = "Please provide additional remarks (e.g., because I need to attend a family event).";
        });
        return;
      }
    }

    if (_remarks != null && (recognized.contains('okay') || recognized.contains('ready'))) {
      _saveToDatabase();
    }
  }

  void _startListening() async {
    if (!_isListening) {
      await _speech.listen(onResult: (result) {
        _processRecognitionResult(result.recognizedWords);
      });
      setState(() {
        _isListening = true;
        _errorMessage = "";
      });
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Leave Application'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            if (_recognizedText.isNotEmpty)
              Text(
                'You said: $_recognizedText',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            if (_isSubmitted) _buildLeaveSummary(), // Display the summary after submission
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_off,
                  size: 80,
                  color: _isListening ? Colors.red : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _isListening ? "Listening..." : "Tap to start listening",
                style: TextStyle(
                  fontSize: 16,
                  color: _isListening ? Colors.red : Colors.black,
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isListening ? null : _startListening,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Start Listening"),
            ),
          ],
        ),
      ),
    );
  }
}
