import '../../parcel/domain/parcel_models.dart';
import 'navigation_models.dart';

/// Determines the best point to navigate a validator to for a given
/// parcel. Preference order:
///
/// 1. A MapX-defined access/navigation point, if the backend provides one.
/// 2. The nearest point on the road/path network to the parcel.
/// 3. The polygon centroid, only as a last-resort fallback.
abstract class ParcelRoutingService {
  Future<ParcelAccessPoint> resolveAccessPoint(LandParcel parcel);
}
