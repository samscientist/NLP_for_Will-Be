import 'dart:convert';
import 'dart:io';

// TODO: implement Preprocess

class Preprocess {
  dynamic _getDataFromJsonFile() {
    final file = File('data.json');
    final jsonString = file.readAsStringSync();
    final map = jsonDecode(jsonString);
    return map;
  }

  Future<Map<String, dynamic>> _getDataFromFirebase() async {
    // TODO: implement _getDataFromFirebase
    throw UnimplementedError();
  }

  // void _modifyMap(Map<String, dynamic> originalData) {
  //   // TODO: implement _modifyMap
  //   // 원하는 정보만을 선택하여 새로운 Map 생성
  //   Map<String, dynamic> selectedData = {
  //     'contexts': [
  //       originalData['contexts'],
  //       for (var key in keys) {
  //         if (key != 'contexts') {
  //           originalData[key],
  //         },
  //       },
  //     ],
  //   };
  //   //final jsonData = jsonEncode(selectedData);
  //   return jsonData;
  // }

}
