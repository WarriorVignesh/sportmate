import 'dart:math';

class DistanceUtil {
  /// Calculates the distance between two geographical points using Haversine formula.
  /// [lat1], [lon1]: Latitude and Longitude of the first point.
  /// [lat2], [lon2]: Latitude and Longitude of the second point.
  /// Returns the distance in kilometers.
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    double dLat = _degreeToRadian(lat2 - lat1);
    double dLon = _degreeToRadian(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreeToRadian(lat1)) * cos(_degreeToRadian(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Returns the distance in kilometers
  }

  /// Helper function to convert degrees to radians
  static double _degreeToRadian(double degree) {
    return degree * pi / 180;
  }
}
