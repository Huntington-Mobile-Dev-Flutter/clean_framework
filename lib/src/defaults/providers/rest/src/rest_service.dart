import 'dart:convert';
import 'dart:typed_data';

import 'package:clean_framework/src/defaults/network_service.dart';
import 'package:clean_framework/src/defaults/providers/rest/rest_logger.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import '../../../../utilities/file.dart';

///
class RestService extends NetworkService {
  /// Default constructor for [RestService].
  RestService({
    String baseUrl = '',
    Map<String, String> headers = const {},
  }) : super(baseUrl: baseUrl, headers: headers);

  Future<T> request<T extends Object>({
    required RestMethod method,
    required String path,
    Map<String, dynamic> data = const {},
    Map<String, String> headers = const {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    Client? client,
  }) async {
    final _client = RestLoggerClient(client ?? Client());

    var uri = _pathToUri(path);

    if (method == RestMethod.get) {
      uri = uri.replace(queryParameters: data);
    }

    try {
      final request = Request(method.value, uri);

      if (headers['Content-Type'] == 'application/x-www-form-urlencoded') {
        request.bodyFields = data.map((k, v) => MapEntry(k, v.toString()));
      } else {
        request.body = jsonEncode(data);
      }

      request.headers
        ..addAll(this.headers!)
        ..addAll(headers);

      final response = await _client.send(request);

      final statusCode = response.statusCode;

      if (statusCode < 200 || statusCode > 299) {
        throw InvalidResponseRestServiceFailure(
          path: uri.toString(),
          error: parseResponse(response),
          statusCode: statusCode,
        );
      }
      if (T == Map<String, dynamic>) {
        final resData = parseResponse(response);
        return resData as T;
      } else if (T == Uint8List || T == List<int>) {
        return response.bodyBytes as T;
      } else {
        throw StateError('The type $T is not supported by request');
      }

      //TODO Enable the types of error we should consider later:
      // } on SocketException {
      //   print('No Internet connection 😑');
      // } on HttpException {
      //   print("Couldn't find the post 😱");
      // } on FormatException {
      //   print("Bad response format 👎");
    } on InvalidResponseRestServiceFailure {
      rethrow;
    } catch (e) {
      //print(e);
      throw RestServiceFailure(e.toString());
    } finally {
      _client.close();
    }
  }

  Future<Map<String, dynamic>> multipartRequest<T extends Object>({
    required RestMethod method,
    required String path,
    Map<String, dynamic> data = const {},
    Map<String, String> headers = const {
      'Content-Type': 'multipart/form-data',
    },
    Client? client,
  }) async {
    final _client = client ?? Client();

    var uri = _pathToUri(path);

    try {
      final request = MultipartRequest(method.value, uri);
      for (final entry in data.entries) {
        final k = entry.key;
        final v = entry.value;
        if (v is File) {
          final stream = ByteStream(v.openRead()..cast());
          final length = await v.length();
          final multipartFile = MultipartFile(
            k,
            stream,
            length,
            filename: basename(v.path),
          );

          request.files.add(multipartFile);
        } else {
          request.fields[k] = v;
        }
      }
      request.headers
        ..addAll(this.headers!)
        ..addAll(headers);

      final streamedResponse = await _client.send(request);
      final response = await Response.fromStream(streamedResponse);

      final statusCode = streamedResponse.statusCode;
      final resData = parseResponse(response);

      if (statusCode < 200 || statusCode > 299) {
        throw InvalidResponseRestServiceFailure(
          path: uri.toString(),
          error: resData,
          statusCode: statusCode,
        );
      }
      return resData;
    } on InvalidResponseRestServiceFailure {
      rethrow;
    } catch (e) {
      throw RestServiceFailure(e.toString());
    } finally {
      _client.close();
    }
  }

  Future<Map<String, dynamic>> binaryRequest({
    required RestMethod method,
    required String path,
    required List<int> data,
    Map<String, String> headers = const {},
    Client? client,
  }) async {
    final _client = client ?? Client();
    var uri = _pathToUri(path);

    try {
      final request = Request(method.value, uri);

      request.bodyBytes = data;

      request.headers
        ..addAll(this.headers!)
        ..addAll(headers);

      final response = await Response.fromStream(await _client.send(request));

      final statusCode = response.statusCode;
      final resData = parseResponse(response);

      if (statusCode < 200 || statusCode > 299) {
        throw InvalidResponseRestServiceFailure(
          path: uri.toString(),
          error: resData,
          statusCode: statusCode,
        );
      }
      return resData;
    } on InvalidResponseRestServiceFailure {
      rethrow;
    } catch (e) {
      throw RestServiceFailure(e.toString());
    } finally {
      _client.close();
    }
  }

  Map<String, dynamic> parseResponse(Response response) {
    final resBody = response.body;
    final resData = resBody.isEmpty ? resBody : jsonDecode(resBody);
    if (resData is Map<String, dynamic>) return resData;
    return {'data': resData};
  }

  Uri _pathToUri(String path) {
    String _url;
    if (baseUrl.isEmpty)
      _url = path;
    else
      _url = '$baseUrl/$path';
    return Uri.parse(_url);
  }
}

class RestServiceFailure {
  final String? message;

  RestServiceFailure([this.message]);
}

class InvalidResponseRestServiceFailure extends RestServiceFailure {
  final String path;
  final int statusCode;
  final Map<String, dynamic> error;

  InvalidResponseRestServiceFailure({
    required this.path,
    required this.error,
    required this.statusCode,
  });
}
