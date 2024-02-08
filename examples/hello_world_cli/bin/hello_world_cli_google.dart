import 'dart:io';

import 'package:langchain/langchain.dart';
import 'package:langchain_google/langchain_google.dart';

void main(final List<String> arguments) async {
  final googleAiApiKey = Platform.environment['GOOGLE_API_KEY'];

  if (googleAiApiKey == null) {
    stderr.writeln('You need to set your Google AI key in the '
        'GOOGLE_API_KEY environment variable.');
    exit(1);
  }

  final llm = ChatGoogleGenerativeAI(
    apiKey: googleAiApiKey,
    defaultOptions: const ChatGoogleGenerativeAIOptions(
      temperature: 0.9,
    ),
  );

  stdout.writeln('무엇을 도와드릴까요?');

  while (true) {
    stdout.write('> ');
    final query = stdin.readLineSync() ?? '';
    final humanMessage = ChatMessage.humanText(query);
    final aiMessage = await llm.call([humanMessage]);
    stdout.writeln(aiMessage.content.trim());
  }
}
