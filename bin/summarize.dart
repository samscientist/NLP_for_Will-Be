import 'dart:io';

import 'package:langchain/langchain.dart';  // -> includes `stuff.dart` and `llm_chain.dart`
// import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_google/langchain_google.dart';

class SummarizeService {
  SummarizeService() {
    final llmApiKey = Platform.environment['GOOGLE_API_KEY'];
    if (llmApiKey == null) {
      stderr.writeln('You need to set your Google API key in the '
          'GOOGLE_API_KEY environment variable.');
      exit(64);
    }
    _llm = ChatGoogleGenerativeAI(
      apiKey: llmApiKey,
      defaultOptions: const ChatGoogleGenerativeAIOptions(
        temperature: 0.9,
      ),
    );
  }

  late final ChatGoogleGenerativeAI _llm;

    final _mapPrompt = PromptTemplate.fromTemplate(
      'Summarize this content: {context}',
    );

    final _reducePrompt = PromptTemplate.fromTemplate(
      'Combine these summaries: {context}',
    );


  Future<String> generateSummary(final List<String> contexts) async {
    final mapLlmChain = LLMChain(prompt: _mapPrompt, llm: _llm);

    final reduceLlmChain = LLMChain(prompt: _reducePrompt, llm: _llm);
    final reduceDocsChain = StuffDocumentsChain(llmChain: reduceLlmChain);
    final reduceChain = MapReduceDocumentsChain(
      mapLlmChain: mapLlmChain,
      reduceDocumentsChain: reduceDocsChain,
    );

    // (Eng) Takes the json-formatted list received in the request, converts it to a Document list, and makes it available to the chain.
    // (한) 요청으로 받은 json 형식의 목록을, Document 리스트로 변환하여 체인에서 사용 가능하게 함.
    final List<Document> docs = contexts.map((final context) => Document(pageContent: context)).toList();

    final res = await reduceChain.run(docs);
    return res;
  }
}

/* Code snippet from LangChain.dart docs - 'Stuff'

```dart
final mapPrompt = PromptTemplate.fromTemplate(
  'Summarize this content: {context}',
);
final mapLlmChain = LLMChain(prompt: mapPrompt, llm: llm);
final reducePrompt = PromptTemplate.fromTemplate(
  'Combine these summaries: {context}',
);
final reduceLlmChain = LLMChain(prompt: reducePrompt, llm: llm);
final reduceDocsChain = StuffDocumentsChain(llmChain: reduceLlmChain);
final reduceChain = MapReduceDocumentsChain(
  mapLlmChain: mapLlmChain,
  reduceDocumentsChain: reduceDocsChain,
);
const docs = [
  Document(pageContent: 'Hello 1!'),
  Document(pageContent: 'Hello 2!'),
  Document(pageContent: 'Hello 3!'),
];
final res = await reduceChain.run(docs);
```

*/
