// ignore_for_file: avoid_dynamic_calls
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'summarize.dart';
//import 'preprocess.dart';

// General Summarizing
// ignore: camel_case_types
class Api_GeneralSummary {
  final summarizeService = SummarizeService();

  Handler get handler {
    final router = Router()..post('/v1/summary', _summaryHandler);
    return router.call;
  }

  Future<Response> _summaryHandler(final Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final contexts = payload['contexts'];

    // List<String>으로 된 contexts를 String으로 변환(`contexts.cast<String>`) 후, 요약 생성 메소드( summarize.dart - generateSummary )로 전달
    final summmary = await summarizeService.generateSummary(contexts.cast<String>()); // ★★  ★★

    return Response.ok(
      headers: {'Content-type': 'application/json'},
      jsonEncode({
        '요약': summmary,
      }),
    );
  }
}

// ignore: camel_case_types
class Api_ReportSummary {
  final summarizeReport = SummarizeReport();

  Handler get handler {
    final router = Router()..post('/v1/summary/report', _summaryHandler);
    return router.call;
  }

  Future<Response> _summaryHandler(final Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final records = payload['records'];

    // List<Map<String, dynamic>>으로 된 records를 String으로 변환(`contexts.cast<String>`) 후, 요약 생성 메소드( summarize.dart - generateSummary )로 전달
    final report = await summarizeReport.generateWeeklyReport(records.cast<Map<String, dynamic>>());

    return Response.ok(
      headers: {'Content-type': 'application/json'},
      jsonEncode({
        '주간 요약': report,
      }),
    );
  }
}
