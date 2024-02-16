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
        temperature: 0.2,
      ),
    );
  }

  late final ChatGoogleGenerativeAI _llm;

  final _mapPromptTemplate = PromptTemplate.fromTemplate(
    // 'Write a concise summary in Korean of this content: {context}',
    '''
    아래의 조건을 만족하며, {context}를 한국어로 요약해주세요.
    - 3인칭 시점
    - 3줄 이하
    ''',
  );
  // String context = 'hello';
  // late final _mapPrompt = _mapPromptTemplate.formatPrompt({'context': context});

  final _reducePromptTemplate = PromptTemplate.fromTemplate(
    // 'Combine these summaries: {context}, and refine it to be coherent',
    '''
    아래의 사항을 고려하며,{context}의 내용을 하나의 글로 정리해주세요.
    - 원본 내용과 다른 내용 없음
    - 한글 맞춤법 검사
    - 글의 통일성
    ''',
  );

  Future<String> generateSummary(final List<String> contexts) async {
    final mapLlmChain = LLMChain(prompt: _mapPromptTemplate, llm: _llm);  // Apply `mapPrompt` to each value
    final reduceLlmChain = LLMChain(prompt: _reducePromptTemplate, llm: _llm);
    final reduceDocsChain = StuffDocumentsChain(llmChain: reduceLlmChain);  // Combine the summaries with `reducePrompt`
    final reduceChain = MapReduceDocumentsChain(
      mapLlmChain: mapLlmChain,
      reduceDocumentsChain: reduceDocsChain,
    );

    // (Eng) After the json format content received as a request is converted to a List of Strings in the API handler method (api.dart - summaryHandler),
    //       it is converted to a Document-type List, making it available to the chain.
    // (한) 요청으로 받은 json 형식의 내용을 API 핸들러 메소드( api.dart - summaryHandler )에서 문자열 리스트로 변환하여 전달하면,
    //     Document형의 리스트로 변환하여 체인에서 사용 가능하게 함. => 아래의 주석 처리된 리스트와 같은 형태를 가지게 된다.
    final List<Document> docs = contexts.map((final context) => Document(pageContent: context)).toList();
    /*
      final docs = [
        Document(pageContent: 'Hello 1!'),
        Document(pageContent: 'Hello 2!'),
        Document(pageContent: 'Hello 3!'),
      ];
    */


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
