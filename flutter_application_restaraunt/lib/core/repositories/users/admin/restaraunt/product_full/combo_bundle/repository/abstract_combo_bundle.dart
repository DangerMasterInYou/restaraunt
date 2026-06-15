import '../combo_bundle.dart';

abstract class AbstractComboBundleRepository {
  Future<List<ComboBundleResponse>> getComboBundleList();
  Future<ComboBundleResponse> getComboBundle(int comboBundleId);
  Future<ComboBundleResponse> postCreateComboBundle(ComboBundleCreateDTO dto);
  Future<ComboBundleResponse> patchComboBundle(
      int comboBundleId, ComboBundlePatchDTO dto);
  Future<void> deleteHardComboBundle(int comboBundleId);
  Future<void> deleteSoftComboBundle(int comboBundleId);
  Future<void> postRestoreComboBundle(int comboBundleId);
}
