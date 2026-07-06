import 'package:flutter/material.dart';
import 'package:luxora/screens/home/favorite_list_screen.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../core/api_media_url.dart';
import '../../core/auth_storage.dart';
import '../../core/local_profile_avatar_cache.dart';
import '../../core/app_localizations.dart';
import '../../widgets/app_background.dart';
import '../../core/app_colors.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'languages_screen.dart';

import '../../core/theme_provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../core/agent_debug_log.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoadingProfile = true;
  String _displayName = '';
  String _email = '';
  String? _avatarUrl;
  String? _localAvatarPath;
  // Bumped after every reload so Image.network gets a fresh key
  int _avatarVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final token = await AuthStorage.getToken();
      // #region agent log
      AgentDebugLog.log(
        runId: 'pre-fix',
        hypothesisId: 'I',
        location: 'settings_screen.dart:_loadProfile:token',
        message: 'Settings token check',
        data: <String, Object?>{'hasToken': token != null && token.isNotEmpty},
      );
      // #endregion
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _isLoadingProfile = false);
        return;
      }

      final response = await _apiService.getCurrentUser();
      if (!mounted) return;
      // #region agent log
      AgentDebugLog.log(
        runId: 'pre-fix',
        hypothesisId: 'I',
        location: 'settings_screen.dart:_loadProfile:response',
        message: 'Settings getCurrentUser response',
        data: <String, Object?>{
          'isSuccess': response.isSuccess,
          'statusCode': response.statusCode,
          'message': response.message,
          'hasData': response.data != null,
        },
      );
      // #endregion
      if (response.isSuccess && response.data != null) {
        final newUrl = ApiMediaUrl.resolve(response.data!.avatarUrl);
        await LocalProfileAvatarCache.reconcileWithServerAvatarUrl(newUrl);
        final localPath = await LocalProfileAvatarCache.getPath();

        // 🔍 DEBUG — remove once avatar upload is confirmed working
        debugPrint('[SettingsScreen] avatarUrl from server: ${response.data!.avatarUrl}');
        debugPrint('[SettingsScreen] resolved URL: $newUrl');

        // #region agent log
        AgentDebugLog.log(
          runId: 'pre-fix',
          hypothesisId: 'H',
          location: 'settings_screen.dart:_loadProfile',
          message: 'Settings profile loaded',
          data: <String, Object?>{
            'hasRemoteUrl': newUrl != null && newUrl.isNotEmpty,
            'hasLocalPath': localPath != null && localPath.isNotEmpty,
          },
        );
        // #endregion

        // Evict the stale cached image before showing the new one
        if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
          await NetworkImage(_avatarUrl!).evict();
        }
        if (newUrl != null && newUrl.isNotEmpty) {
          await NetworkImage(newUrl).evict();
        }

        if (!mounted) return;
        setState(() {
          _displayName = response.data!.name;
          _email = response.data!.email;
          _avatarUrl = newUrl;
          _localAvatarPath = localPath;
          _avatarVersion++; // forces widget to rebuild with the fresh URL
          _isLoadingProfile = false;
        });
      } else {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
      debugPrint('Settings profile exception: $e');
    }
  }

  /// Appends a version query param to bust Flutter's image cache.
  String _bustedUrl(String url) =>
      url.contains('?') ? '$url&v=$_avatarVersion' : '$url?v=$_avatarVersion';

  Future<void> _logout(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await const AuthService().logout();
    } catch (_) {}

    if (!context.mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Logged out')));
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final loc = AppLocalizations.of(context);

    return AppBackground(
      overlayColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.6),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Text(
                loc.translate('settings'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 30),

              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                child: ClipOval(
                  child: (_localAvatarPath != null &&
                          _localAvatarPath!.isNotEmpty &&
                          File(_localAvatarPath!).existsSync())
                      ? Image.file(
                          File(_localAvatarPath!),
                          key: ValueKey('settings_local_avatar_$_avatarVersion'),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                          ? Image.network(
                              _bustedUrl(_avatarUrl!),
                              key: ValueKey('settings_avatar_$_avatarVersion'),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 40,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _isLoadingProfile ? '…' : (_displayName.isEmpty ? '—' : _displayName),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              Text(
                _isLoadingProfile ? '' : (_email.isEmpty ? '—' : _email),
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              /// ❤️ Favourite List
              _item(Icons.favorite_border, loc.translate('favouriteList'), onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoriteListScreen()),
                );
              }),

              /// 🌍 Language
              _item(Icons.language, loc.translate('language'), onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguagesScreen()),
                );
              }),

              /// 👤 Profile — reload avatar when returning
              _item(Icons.person_outline, loc.translate('profile'), onTap: () {
                AgentDebugLog.log(
                  runId: 'pre-fix',
                  hypothesisId: 'D',
                  location: 'settings_screen.dart:Profile:onTap',
                  message: 'Settings -> Profile tapped',
                  data: const <String, Object?>{},
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ).then((_) {
                  // Re-fetch profile (and bust image cache) when user comes back
                  _loadProfile();
                });
              }),

              /// 🌙 Appearance
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                title: Text(loc.translate('appearance')),
                trailing: Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ),

              /// 🚪 Logout
              _item(Icons.logout, loc.translate('logout'), onTap: () => _logout(context)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _item(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
