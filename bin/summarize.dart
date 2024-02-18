import 'dart:io';

import 'package:langchain/langchain.dart';  // -> includes `stuff.dart` and `llm_chain.dart`
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
        model: 'gemini-pro',
        temperature: 0,
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
    final mapLlmChain = LLMChain(prompt: _mapPromptTemplate, llm: _llm);  // Define what prompt to apply, and what LLM to use; for each doc
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
        Document(pageContent: '...'),
        Document(pageContent: '...'),
        ...
        Document(pageContent: '...'),
      ];
    */

    final res = await reduceChain.run(docs);
    return res;
  }
}


class SummarizeReport extends SummarizeService {
  // late final ChatGoogleGenerativeAI _llm;

  // ↱ 린터 오해로 보이며, 이에 따라 무시 처리
  // ignore: annotate_overrides, overridden_fields
  final _refineDailyReportPrompt = PromptTemplate.fromTemplate(
    // 'Write a concise summary in Korean of this content: {context}',
    '''
    아래의 조건을 만족하며, {record}의 내용을 종합하여 정리해주세요.
    - 분량: 문장 3개 이하
    - 언어: 한국어 문어체
    - 시점: 3인칭
    - 항목 설명: 'stamps'-발생 시각; 'situation'-상황; 'action'-조치; 'etc'-특이사항;
    - 형식: "<상황>에서 <행동>을 하고, 이에 따라 <조치>를 했다(<빈도>번). 이에 대해, <특이사항>" ('<'와 '>'로 감싼 내용은 Nonterminal Symbol로, 채워야 하는 영역)
    - 기타: 빈도는 발생 시각의 개수에서 추출
    - 예시: "수업 시간에 의자에 앉아야 하는 상황에서 의자에 앉지 않고 누워서 소리지름 (3번). 이에 따라 환경 분리 조치를 취함. 하지만 행동은 나아지지 않고 오히려 심해짐."
    ''',
  );

  // ignore: annotate_overrides, overridden_fields
  final _summarizeWeekPrompt = PromptTemplate.fromTemplate(
    // 'Combine these summaries: {context}, and refine it to be coherent',
    '''
    아래의 사항을 고려하며, {record}의 내용을 하나의 글로 정리해주세요.
    - '~일차'의 형식으로 묶어서 정리, 순서대로 나열
    - 모든 {record}에 대한 언급, 만야 다섯 개의 묶음이 있다면 다섯 개 모두 표현
    - 원본 내용 다른 내용은 포함하지 않음
    - 한글 맞춤법 검사
    ''',
  );

  Future<String> generateWeeklyReport(final List<dynamic> records) async {  // { "records":[ {}, {}, ... ] }
    // ignore: non_constant_identifier_names
    final llmChain_organizeDailyReport = LLMChain(prompt: _refineDailyReportPrompt, llm: _llm);  // Define what prompt to apply, and what LLM to use; for each doc
    // ignore: non_constant_identifier_names
    final llmChain_weeklyReport = LLMChain(prompt: _summarizeWeekPrompt, llm: _llm);

    final dailyReportChain = StuffDocumentsChain(llmChain: llmChain_weeklyReport);  // Combine the summaries with `reducePrompt`
    // final weeklyReportChain = StuffDocumentsChain(llmChain: llmChain_weeklyReport);  // Combine the summaries with `reducePrompt`
    
    final weeklyReportChain = MapReduceDocumentsChain(
      mapLlmChain: llmChain_organizeDailyReport,
      reduceDocumentsChain: dailyReportChain,
    );
    
    ////final dailyReport = await dailyReportChain.run(contexts);

    final List<Document> docs = records.map((final record) => Document(pageContent: record.toString())).toList();

    final res = await weeklyReportChain.run(docs);
    return res;
  }
}
