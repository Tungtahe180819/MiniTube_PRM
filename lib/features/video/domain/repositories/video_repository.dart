import '../../../../core/domain/models.dart';

abstract class VideoRepository {
  Future<List<Category>> categories();
  Future<PageResult<Video>> videos({
    String? query,
    String? categoryId,
    int page = 1,
  });
}
