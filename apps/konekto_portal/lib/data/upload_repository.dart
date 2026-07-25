import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:konekto_portal/api_config.dart';

/// Upload de imagem (logo, carrossel, banner de Serviços, item do
/// cardápio, cupom) — sobe o arquivo pro backend, que guarda no Vercel
/// Blob e devolve a URL pública pronta pra colar no campo de imagem.
class UploadRepository {
  final http.Client _client;

  UploadRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<String> uploadImage({
    required String hotelId,
    required String token,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/uploads'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 415) {
      throw StateError('Formato de imagem não suportado — use JPEG, PNG, WebP, GIF ou AVIF.');
    }
    if (response.statusCode == 413) {
      throw StateError('Imagem muito grande — o limite é 4MB.');
    }
    if (response.statusCode != 201) {
      throw StateError('Falha ao enviar a imagem (status ${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['url'] as String;
  }
}
