package io.flutter.plugins;

import io.flutter.plugin.common.PluginRegistry;
import app.dev.flutter_facebook_pro.FlutterFacebookSdkPlugin;

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
    if (alreadyRegisteredWith(registry)) {
      return;
    }
    FlutterFacebookSdkPlugin.registerWith(registry.registrarFor("app.dev.flutter_facebook_pro.FlutterFacebookSdkPlugin"));
  }

  private static boolean alreadyRegisteredWith(PluginRegistry registry) {
    final String key = GeneratedPluginRegistrant.class.getCanonicalName();
    if (registry.hasPlugin(key)) {
      return true;
    }
    registry.registrarFor(key);
    return false;
  }
}
