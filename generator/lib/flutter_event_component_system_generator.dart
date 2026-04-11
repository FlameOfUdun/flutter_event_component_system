import 'package:build/build.dart';

import 'src/builders/feature_builder.dart';

Builder ecsBuilder(BuilderOptions options) {
  return FeatureBuilder();
}
