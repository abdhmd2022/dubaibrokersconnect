import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

Future<String> readReraCardText(html.File file) async {

  final reader = html.FileReader();
  reader.readAsDataUrl(file);
  await reader.onLoad.first;

  final imageData = reader.result;

  final promise = js_util.callMethod(
    js_util.getProperty(js_util.globalThis, 'Tesseract'),
    'recognize',
    [
      imageData,
      'eng+ara',
    ],
  );

  final result = await js_util.promiseToFuture(promise);

  final text = js_util.getProperty(
      js_util.getProperty(result, 'data'),
      'text'
  );

  return text;
}