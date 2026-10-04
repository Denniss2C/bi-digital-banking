import 'package:flutter/widgets.dart';
import 'package:sdui/src/components/promo_banner.dart';
import 'package:sdui/src/components/quick_actions.dart';
import 'package:sdui/src/model/sdui_props.dart';
import 'package:sdui/src/registry/sdui_registry.dart';
import 'package:sdui/src/rendering/sdui_view.dart';

/// Components that need no data from any feature, ready to register:
/// `registry.registerAll(standardSduiComponents)`.
const standardSduiComponents = <String, SduiComponentBuilder>{
  'promo_banner': _promoBanner,
  'quick_actions': _quickActions,
};

Widget _promoBanner(
  BuildContext context,
  SduiProps props,
  SduiActionHandler onAction,
) => PromoBanner.fromProps(
  props,
  languageCode: context.sduiLanguageCode,
  onAction: onAction,
);

Widget _quickActions(
  BuildContext context,
  SduiProps props,
  SduiActionHandler onAction,
) => QuickActions.fromProps(
  props,
  languageCode: context.sduiLanguageCode,
  onAction: onAction,
);
