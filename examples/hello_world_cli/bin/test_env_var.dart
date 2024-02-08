import 'dart:io';


void main(){
  final googleAiApiKey = Platform.environment['GOOGLE_API_KEY'];
  stdout.write(googleAiApiKey);
}
