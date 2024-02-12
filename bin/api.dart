// ignore_for_file: avoid_dynamic_calls
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'summarize.dart';

class Api {
  final summarizeService = SummarizeService();

  Handler get handler {
    final router = Router()..post('/v1/summary', _summaryHandler);
    return router.call;
  }

  Future<Response> _summaryHandler(final Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final contexts = payload['contexts'];

    final summmary = await summarizeService.generateSummary(contexts.cast<String>());  // List<String>으로 변환하여 요약 생성 메소드( summarize.dart - generateSummary )로 전달

    return Response.ok(
      headers: {'Content-type': 'application/json'},
      jsonEncode({
        '요약': summmary,
      }),
    );
  }
}
