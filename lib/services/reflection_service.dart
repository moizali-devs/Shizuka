import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shizuka/core/config.dart';
import 'package:shizuka/repositories/checkin_repository.dart';
import 'package:shizuka/repositories/intention_repository.dart';
import 'package:shizuka/repositories/room_repository.dart';

class ReflectionResult {
  const ReflectionResult({
    required this.reflectionText,
    required this.durationMinutes,
    required this.memberCount,
    required this.blockCount,
  });

  final String reflectionText;
  final int durationMinutes;
  final int memberCount;
  final int blockCount;
}

class ReflectionService {
  ReflectionService({
    FirebaseFirestore? firestore,
    http.Client? httpClient,
    IntentionRepository? intentionRepository,
    CheckInRepository? checkInRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _http = httpClient ?? http.Client(),
        _intentionRepo = intentionRepository ?? IntentionRepository(),
        _checkInRepo = checkInRepository ?? CheckInRepository();

  final FirebaseFirestore _firestore;
  final http.Client _http;
  final IntentionRepository _intentionRepo;
  final CheckInRepository _checkInRepo;

  static const _systemPrompt =
      'You are a thoughtful, calm focus coach. The user just completed a '
      'focused work session. Write exactly one short paragraph (3–4 sentences) '
      'reflecting on their session. Be warm, non-judgmental, and gently '
      'encouraging. Do not use lists or headers.';

  /// Fetches the user's intentions and check-ins, generates an AI reflection,
  /// saves it to Firestore, and returns the result.
  Future<ReflectionResult> generateAndSave({
    required String uid,
    required Room room,
  }) async {
    final roomId = room.roomId;

    // --- Gather session data -------------------------------------------------
    final intentions =
        await _intentionRepo.watchIntentions(roomId).first;
    final block1 = await _checkInRepo.watchCheckIns(roomId, 1).first;
    final block2 = await _checkInRepo.watchCheckIns(roomId, 2).first;

    final intentionText = intentions[uid]?.text;
    final block1Text = block1[uid]?.text;
    final block2Text = block2[uid]?.text;
    final memberCount = room.members.length;
    final blockCount = block2.isNotEmpty ? 2 : 1;

    final durationMinutes = room.sessionStartedAt != null
        ? DateTime.now().difference(room.sessionStartedAt!).inMinutes
        : (blockCount == 2 ? 100 : 45);

    // --- Build prompt --------------------------------------------------------
    final userPrompt = _buildUserPrompt(
      intentionText: intentionText,
      block1Text: block1Text,
      block2Text: block2Text,
      memberCount: memberCount,
      durationMinutes: durationMinutes,
      blockCount: blockCount,
    );

    // --- Call OpenAI ---------------------------------------------------------
    final reflectionText =
        await _callOpenAi(userPrompt: userPrompt);

    // --- Save to Firestore ---------------------------------------------------
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('reflections')
        .doc(roomId)
        .set({
      'roomId': roomId,
      'createdAt': FieldValue.serverTimestamp(),
      'reflectionText': reflectionText,
      'durationMinutes': durationMinutes,
      'memberCount': memberCount,
      'blockCount': blockCount,
    });

    return ReflectionResult(
      reflectionText: reflectionText,
      durationMinutes: durationMinutes,
      memberCount: memberCount,
      blockCount: blockCount,
    );
  }

  String _buildUserPrompt({
    required String? intentionText,
    required String? block1Text,
    required String? block2Text,
    required int memberCount,
    required int durationMinutes,
    required int blockCount,
  }) {
    final buf = StringBuffer();
    buf.writeln(
      'I just completed a $blockCount-block focus session '
      '(approximately $durationMinutes minutes) '
      'with ${memberCount - 1} other ${memberCount - 1 == 1 ? 'person' : 'people'}.',
    );
    buf.writeln();
    if (intentionText != null) {
      buf.writeln('My intention was: $intentionText');
    }
    if (block1Text != null) {
      buf.writeln('After block 1, I wrote: $block1Text');
    }
    if (block2Text != null) {
      buf.writeln('After block 2, I wrote: $block2Text');
    }
    buf.writeln();
    buf.write('Please give me a brief personal reflection on my session.');
    return buf.toString();
  }

  Future<String> _callOpenAi({required String userPrompt}) async {
    final response = await _http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $kOpenAiApiKey',
      },
      body: jsonEncode({
        'model': kReflectionModel,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'max_tokens': 200,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI request failed (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (body['choices'] as List).first['message']['content'] as String;
    return text.trim();
  }
}
