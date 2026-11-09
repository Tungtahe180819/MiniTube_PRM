import '../../../../core/media/upload_source.dart';

import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../../../core/errors/app_exception.dart';

import '../../../../core/domain/models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import 'video_repository_impl.dart';

class RemoteVideoRepository extends MockVideoRepository {
  final api = ApiClient.shared;
  final uploadProgress = ValueNotifier<double?>(null);
  dio.CancelToken? _uploadToken;
  void cancelUpload() {
    _uploadToken?.cancel('Canceled by user');
  }

  RemoteVideoRepository() {
    items.clear();
  }
  Video parse(Map<String, dynamic> data) {
    final j = Map<String, dynamic>.from(data);
    j['videoUrl'] = Uri.parse(ApiConstants.baseUrl)
        .resolve(j['videoUrl'])
        .toString();
    return Video.fromJson(j);
  }

  void cache(Video v) {
    items.removeWhere((e) => e.id == v.id);
    items.add(v);
  }

  @override
  Future<List<Category>> categories() async =>
      ((await api.request('GET', '/categories'))['data'] as List)
          .map((e) => Category.fromJson(e))
          .toList();
  @override
  Future<PageResult<Video>> videos({
    String? query,
    String? categoryId,
    int page = 1,
  }) async {
    final j = await api.request(
      'GET',
      '/videos',
      query: {'page': '$page', 'q': ?query, 'categoryId': ?categoryId},
    );
    final values = (j['data'] as List).map((e) => parse(e)).toList();
    for (final v in values) {
      cache(v);
    }
    return PageResult(
      values,
      int.parse(j['meta']['total'].toString()),
      page,
      20,
    );
  }

  @override
  Future<Video> persistVideo(
    User user,
    VideoWrite input, {
    String? id,
    PlatformFile? file,
  }) async {
    dynamic result;
    if (id != null && file == null) {
      result = await api.request(
        'PUT',
        '/videos/$id',
        body: {
          'title': input.title,
          'description': input.description,
          'categoryId': input.categoryId,
          'thumbnailUrl': input.thumbnailUrl ?? '',
        },
      );
    } else {
      if (file == null) throw StateError('Choose a video file.');
      final client = dio.Dio();
      final cancel = dio.CancelToken();
      _uploadToken = cancel;
      uploadProgress.value = 0;
      try {
        final form = dio.FormData.fromMap({
          'title': input.title,
          'description': input.description,
          'categoryId': input.categoryId,
          'thumbnailUrl': input.thumbnailUrl ?? '',
          'video': dio.MultipartFile.fromStream(
            () => uploadSource(file),
            file.size,
            filename: file.name,
          ),
        });
        final response = await client.request(
          api.uri(id == null ? '/videos' : '/videos/$id/file').toString(),
          data: form,
          options: dio.Options(
            method: id == null ? 'POST' : 'PUT',
            headers: {'Authorization': 'Bearer ${api.token}'},
            sendTimeout: const Duration(minutes: 5),
            receiveTimeout: const Duration(minutes: 1),
          ),
          cancelToken: cancel,
          onSendProgress: (sent, total) {
            if (total > 0) uploadProgress.value = (sent / total).clamp(0, 1);
          },
        );
        result = response.data;
      } on dio.DioException catch (e) {
        if (dio.CancelToken.isCancel(e)) {
          throw const AppException(
            'Upload stopped. Refresh Manage Videos to check whether the server already completed it before retrying.',
          );
        }
        final data = e.response?.data;
        final error = data is Map ? data['error'] : null;
        throw AppException(
          error is Map
              ? error['message'].toString()
              : 'Upload failed. Check your connection and retry.',
        );
      } finally {
        _uploadToken = null;
        client.close(force: true);
        uploadProgress.value = null;
      }
    }
    final value = parse(result['data']);
    cache(value);
    revision.value++;
    return value;
  }

  @override
  Future<void> removeVideo(String id, User user) async {
    await api.request('DELETE', '/videos/$id');
    items.removeWhere((v) => v.id == id);
    revision.value++;
  }

  Future<void> loadMine() async {
    final j = await api.request('GET', '/me/videos');
    items.clear();
    for (final v in j['data']) {
      cache(parse(v));
    }
  }

  @override
  Future<List<Comment>> fetchComments(String id) async =>
      ((await api.request('GET', '/videos/$id/comments'))['data'] as List)
          .map((j) => Comment.fromJson(j))
          .toList();
  @override
  Future<void> postComment(String id, User author, String content) async {
    await api.request(
      'POST',
      '/videos/$id/comments',
      body: {'content': content},
    );
  }

  @override
  Future<void> removeComment(String id, String userId) async {
    await api.request('DELETE', '/comments/$id');
  }

  @override
  Future<void> trackHistory(String userId, String videoId) async {
    await api.request('PUT', '/me/history/$videoId');
  }

  @override
  Future<PageResult<HistoryItem>> fetchHistory(
    String userId, {
    int page = 1,
  }) async {
    final j = await api.request('GET', '/me/history', query: {'page': '$page'});
    final entries = (j['data'] as List).map((e) {
      final v = parse(e['video']);
      cache(v);
      return HistoryItem(v, DateTime.parse(e['lastWatchedAt']));
    }).toList();
    return PageResult(
      entries,
      int.parse(j['meta']['total'].toString()),
      page,
      20,
    );
  }

  @override
  Future<void> removeHistory(String userId, {String? videoId}) async {
    await api.request(
      'DELETE',
      videoId == null ? '/me/history' : '/me/history/$videoId',
    );
  }

  @override
  Future<Channel> fetchMyChannel(User user) async =>
      Channel.fromJson((await api.request('GET', '/me/channel'))['data']);
  @override
  Future<void> saveChannel(
    User user,
    String name,
    String description,
    String? avatar,
  ) async {
    await api.request(
      'PUT',
      '/me/channel',
      body: {'name': name, 'description': description, 'avatarUrl': avatar},
    );
    revision.value++;
  }

  @override
  Future<Channel> fetchChannel(String id) async =>
      Channel.fromJson((await api.request('GET', '/channels/$id'))['data']);
  @override
  Future<List<Video>> channelVideos(String id) async {
    final values =
        ((await api.request('GET', '/channels/$id/videos'))['data'] as List)
            .map((e) => parse(e))
            .toList();
    for (final v in values) {
      cache(v);
    }
    return values;
  }
}
