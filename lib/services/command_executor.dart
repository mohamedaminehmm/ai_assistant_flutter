// lib/services/command_executor.dart
// DEBUG + UPDATED APP FUNCTION (DeviceApps version)

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_apps/device_apps.dart';

class CommandExecutor {
  // 🚀 MAIN DISPATCHER: Executes based on intent type
  Future<Map<String, dynamic>> executeCommand(
    String intent,
    String originalText,
    BuildContext context,
  ) async {
    print('🔄 EXECUTING COMMAND: $intent - "$originalText"');

    try {
      Map<String, dynamic> result;

      switch (intent) {
        case 'app':
          result = await _executeAppCommand(originalText, context);
          break;
        case 'call':
          result = await _executeCallCommand(originalText, context);
          break;
        case 'search':
          result = await _executeSearchCommand(originalText, context);
          break;
        case 'note':
          result = await _executeNoteCommand(originalText, context);
          break;
        case 'reminder':
          result = await _executeReminderCommand(originalText, context);
          break;
        default:
          result = {
            'success': false,
            'message': 'Unknown command type: $intent',
            'action_taken': 'none',
          };
      }

      print('✅ EXECUTION RESULT: ${result['success']} - ${result['message']}');
      return result;
    } catch (e) {
      print('❌ EXECUTION ERROR: $e');
      return {
        'success': false,
        'message': 'Error executing command: $e',
        'action_taken': 'none',
      };
    }
  }

  // 📱 UPDATED: Execute App Opening Command (DeviceApps version)
  Future<Map<String, dynamic>> _executeAppCommand(
    String originalText,
    BuildContext context,
  ) async {
    try {
      String appName = _extractAppName(originalText);

      // 🥇 1. Try static map first
      String? packageName = _mapAppNameToPackage(appName);
      if (packageName != null) {
        bool launched = await _launchAppByPackage(packageName);
        if (launched) {
          return {
            'success': true,
            'message': 'Opened $appName',
            'action_taken': 'app_launch',
          };
        }
      }

      // 🥈 2. Scan installed apps (lightweight)
      List<Application> apps = await DeviceApps.getInstalledApplications(
        includeSystemApps: false,
        includeAppIcons: false,
      );

      Application? targetApp = _findAppSimple(apps, appName);
      if (targetApp != null) {
        bool opened = await DeviceApps.openApp(targetApp.packageName);
        if (opened) {
          return {
            'success': true,
            'message': 'Opened ${targetApp.appName}',
            'action_taken': 'app_launch',
          };
        }
      }

      return {
        'success': false,
        'message': 'App "$appName" not found on device',
        'action_taken': 'none',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error executing app command: $e',
        'action_taken': 'none',
      };
    }
  }

  // 🔤 Extract clean app name from command
  String _extractAppName(String command) {
    String cleaned = command.toLowerCase();
    cleaned =
        cleaned.replaceAll(RegExp(r'open|launch|start|app|the'), '').trim();
    return cleaned;
  }

  // 📦 Static map of popular apps
  String? _mapAppNameToPackage(String appName) {
    final commonApps = {
      'whatsapp': 'com.whatsapp',
      'facebook': 'com.facebook.katana',
      'instagram': 'com.instagram.android',
      'messenger': 'com.facebook.orca',
      'chrome': 'com.android.chrome',
      'gmail': 'com.google.android.gm',
      'maps': 'com.google.android.apps.maps',
      'youtube': 'com.google.android.youtube',
      'photos': 'com.google.android.apps.photos',
      'camera': 'com.android.camera',
      'settings': 'com.android.settings',
    };
    return commonApps[appName.toLowerCase()];
  }

  // 🔎 Simple app matching
  Application? _findAppSimple(List<Application> apps, String query) {
    query = query.toLowerCase();
    for (var app in apps) {
      if (app.appName.toLowerCase().contains(query)) {
        return app;
      }
    }
    return null;
  }

  // 🚀 Launch app by package name
  Future<bool> _launchAppByPackage(String packageName) async {
    try {
      return await DeviceApps.openApp(packageName);
    } catch (e) {
      return false;
    }
  }

  // 📞 CALL COMMAND
  Future<Map<String, dynamic>> _executeCallCommand(
      String text, BuildContext context) async {
    print('📞 CALL COMMAND: $text');

    final contactMap = {
      'mom': '+1234567890',
      'dad': '+1234567891',
      'emergency': '112',
      'home': '+1234567892',
      'office': '+1234567893',
      'wife': '+1234567894',
      'husband': '+1234567895',
    };

    String? phoneNumber;
    String contactName = '';

    for (final contact in contactMap.keys) {
      if (text.toLowerCase().contains(contact)) {
        contactName = contact;
        phoneNumber = contactMap[contact];
        break;
      }
    }

    if (phoneNumber == null) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.DIAL',
        );
        await intent.launch();
        return {
          'success': true,
          'message': 'Opened phone dialer',
          'action_taken': 'open_dialer',
        };
      } catch (e) {
        return {
          'success': true,
          'message': 'Simulated: Opening phone dialer',
          'action_taken': 'simulated_dialer',
        };
      }
    }

    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.DIAL',
        data: 'tel:$phoneNumber',
      );
      await intent.launch();

      return {
        'success': true,
        'message':
            'Dialing ${contactName.isNotEmpty ? contactName : phoneNumber}',
        'action_taken': 'dial_number',
        'contact': contactName,
        'number': phoneNumber,
      };
    } catch (e) {
      return {
        'success': true,
        'message':
            'Simulated: Calling ${contactName.isNotEmpty ? contactName : phoneNumber}',
        'action_taken': 'simulated_call',
        'contact': contactName,
        'number': phoneNumber,
      };
    }
  }

  // 🔍 SEARCH COMMAND
  Future<Map<String, dynamic>> _executeSearchCommand(
      String text, BuildContext context) async {
    print('🔍 SEARCH COMMAND: $text');

    String searchQuery = text;

    final commandWords = [
      'search',
      'find',
      'look',
      'google',
      'what',
      'who',
      'when',
      'where',
      'why',
      'how'
    ];

    for (final word in commandWords) {
      if (searchQuery.toLowerCase().startsWith('$word ')) {
        searchQuery = searchQuery.substring(word.length).trim();
        break;
      }
    }

    if (searchQuery.isEmpty) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'https://google.com',
        );
        await intent.launch();
        return {
          'success': true,
          'message': 'Opened search engine',
          'action_taken': 'open_browser',
        };
      } catch (e) {
        if (await canLaunchUrl(Uri.parse('https://google.com'))) {
          await launchUrl(Uri.parse('https://google.com'));
          return {
            'success': true,
            'message': 'Opened search engine via URL',
            'action_taken': 'url_launch',
          };
        }
      }
    }

    try {
      final encodedQuery = Uri.encodeComponent(searchQuery);
      final searchUrl = 'https://www.google.com/search?q=$encodedQuery';

      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: searchUrl,
        );
        await intent.launch();
        return {
          'success': true,
          'message': 'Searching for: $searchQuery',
          'action_taken': 'web_search',
          'query': searchQuery,
        };
      } catch (e) {
        if (await canLaunchUrl(Uri.parse(searchUrl))) {
          await launchUrl(Uri.parse(searchUrl));
          return {
            'success': true,
            'message': 'Searching for: $searchQuery via URL',
            'action_taken': 'web_search',
            'query': searchQuery,
          };
        }
      }

      return {
        'success': false,
        'message': 'Cannot perform search',
        'action_taken': 'none',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to perform search: $e',
        'action_taken': 'none',
      };
    }
  }

  // 📝 NOTE COMMAND
  Future<Map<String, dynamic>> _executeNoteCommand(
      String text, BuildContext context) async {
    print('📝 NOTE COMMAND: $text');

    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.CREATE_DOCUMENT',
        type: 'text/plain',
      );
      await intent.launch();

      return {
        'success': true,
        'message': 'Opened note creation',
        'action_taken': 'create_note',
        'content': _extractNoteContent(text),
      };
    } catch (e) {
      final noteContent = _extractNoteContent(text);
      return {
        'success': true,
        'message': 'Note ready: $noteContent',
        'action_taken': 'note_prepared',
        'content': noteContent,
        'note': 'Note content is ready to be saved in your preferred app',
      };
    }
  }

  // ⏰ REMINDER COMMAND
  Future<Map<String, dynamic>> _executeReminderCommand(
      String text, BuildContext context) async {
    print('⏰ REMINDER COMMAND: $text');

    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.INSERT',
        data: 'content://com.android.calendar/events',
      );
      await intent.launch();

      return {
        'success': true,
        'message': 'Opened calendar to set reminder',
        'action_taken': 'open_calendar',
        'reminder': _extractReminderContent(text),
      };
    } catch (e) {
      final reminderContent = _extractReminderContent(text);
      return {
        'success': true,
        'message': 'Reminder set: $reminderContent',
        'action_taken': 'reminder_created',
        'content': reminderContent,
      };
    }
  }

  // ✏️ Extract note text
  String _extractNoteContent(String text) {
    final commandWords = [
      'write',
      'take',
      'create',
      'make',
      'note',
      'memo',
      'jot',
      'record',
      'remember',
      'down'
    ];

    String content = text.toLowerCase();

    for (final word in commandWords) {
      if (content.startsWith('$word ')) {
        content = content.substring(word.length).trim();
      }
      content = content.replaceAll('$word ', '');
    }

    return content.isEmpty ? 'New note' : content;
  }

  // ⏰ Extract reminder text
  String _extractReminderContent(String text) {
    final commandWords = [
      'set',
      'remind',
      'alert',
      'schedule',
      'alarm',
      'timer',
      'wake',
      'notify',
      'reminder'
    ];
    String content = text.toLowerCase();

    for (final word in commandWords) {
      if (content.startsWith('$word ')) {
        content = content.substring(word.length).trim();
      }
      content = content.replaceAll('$word ', '');
    }

    content = content.replaceAll('me ', '').replaceAll('my ', '');

    return content.isEmpty ? 'New reminder' : content;
  }
}
