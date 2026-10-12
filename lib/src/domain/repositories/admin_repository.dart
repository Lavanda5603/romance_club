// Контракт админ-репозитория
abstract class AdminRepository {
  // Удалить ассет
  Future<bool> deleteAsset(String assetId);

  // Удалить эпизод
  Future<bool> deleteEpisode(int episodeId);
}