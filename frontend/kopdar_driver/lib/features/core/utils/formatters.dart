export 'package:kopdar_driver/core/utils/formatters.dart';

extension RewardPointsCompatibility on Object {
  int get pointsCost => (this as dynamic).points as int;
}
