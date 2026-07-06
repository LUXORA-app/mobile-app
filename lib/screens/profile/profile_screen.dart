import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/api_media_url.dart';
import '../../core/auth_storage.dart';
import '../../core/local_profile_avatar_cache.dart';
import '../../widgets/app_background.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../core/agent_debug_log.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  // 🔹 Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // 🔹 Displayed Data
  String displayName = '';

  String? _remoteAvatarUrl;
  String? _localAvatarPath;
  // Bumped after every successful save to bust Flutter's network image cache
  int _avatarVersion = 0;
  bool _loadingProfile = true;

  // 🔹 Password Visibility
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool _isSaving = false;

  // 🔹 Nationality
  String? selectedNationality = "Egyptian";
  final List<String> nationalities = [
    "Egyptian",
    "American",
    "French",
    "German",
    "Italian",
  ];

  // 🔹 Image Picker
  File? profileImage;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    AgentDebugLog.log(
      runId: 'pre-fix',
      hypothesisId: 'D',
      location: 'profile_screen.dart:initState',
      message: 'ProfileScreen initState',
      data: const <String, Object?>{},
    );
    _hydrateLocalAvatarPath();
    _loadProfile();
  }

  Future<void> _hydrateLocalAvatarPath() async {
    final path = await LocalProfileAvatarCache.getPath();
    if (!mounted) return;
    if (path == null || path.isEmpty) return;
    setState(() => _localAvatarPath = path);
  }

  Future<void> _loadProfile() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }
    final response = await _apiService.getCurrentUser();
    if (!mounted) return;
    if (response.isSuccess && response.data != null) {
      final u = response.data!;
      final resolved = ApiMediaUrl.resolve(u.avatarUrl);
      await LocalProfileAvatarCache.reconcileWithServerAvatarUrl(resolved);
      final path = await LocalProfileAvatarCache.getPath();
      if (!mounted) return;
      setState(() {
        nameController.text = u.name;
        emailController.text = u.email;
        if (u.nationality != null && u.nationality!.isNotEmpty) {
          selectedNationality = u.nationality;
        }
        displayName = u.name;
        _remoteAvatarUrl = resolved;
        _localAvatarPath = path;
        _loadingProfile = false;
      });
    } else {
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open gallery: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final response = await _apiService.updateProfile(
      name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
      nationality: selectedNationality,
      password: passwordController.text.trim().isEmpty ? null : passwordController.text.trim(),
      passwordConfirmation: confirmPasswordController.text.trim().isEmpty
          ? null
          : confirmPasswordController.text.trim(),
      avatarFile: profileImage,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!response.isSuccess || response.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Failed to update profile')),
      );
      return;
    }

    final newUrl = ApiMediaUrl.resolve(response.data!.avatarUrl);

    // 🔍 DEBUG — remove once avatar upload is confirmed working
    debugPrint('[ProfileScreen] avatarUrl from server: ${response.data!.avatarUrl}');
    debugPrint('[ProfileScreen] resolved URL: $newUrl');

    // Evict stale cached images so Image.network reloads them
    if (_remoteAvatarUrl != null && _remoteAvatarUrl!.isNotEmpty) {
      await NetworkImage(_remoteAvatarUrl!).evict();
    }
    if (newUrl != null && newUrl.isNotEmpty) {
      await NetworkImage(newUrl).evict();
    }

    String? cachedPath = _localAvatarPath;
    if (profileImage != null) {
      cachedPath = await LocalProfileAvatarCache.saveFromPick(profileImage!);
      await LocalProfileAvatarCache.rememberServerAvatarUrl(newUrl);
      // #region agent log
      AgentDebugLog.log(
        runId: 'pre-fix',
        hypothesisId: 'H',
        location: 'profile_screen.dart:_saveProfile:cached-avatar',
        message: 'Persisted local avatar after successful upload',
        data: <String, Object?>{
          'hasCachedPath': cachedPath != null && cachedPath.isNotEmpty,
        },
      );
      // #endregion
    }

    setState(() {
      displayName = response.data!.name;
      _remoteAvatarUrl = newUrl;
      _avatarVersion++; // forces widget rebuild with fresh URL key
      if (cachedPath != null && cachedPath.isNotEmpty) {
        _localAvatarPath = cachedPath;
      }
      profileImage = null;
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  /// Appends a version query param to bust Flutter's image cache.
  String _bustedUrl(String url) =>
      url.contains('?') ? '$url&v=$_avatarVersion' : '$url?v=$_avatarVersion';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool nationalityInList =
        selectedNationality != null && nationalities.contains(selectedNationality);
    final String? dropdownNationalityValue =
        nationalityInList ? selectedNationality : null;

    return AppBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 30),

            const Center(
              child: Text(
                "Profile",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Profile Image
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: ClipOval(
                      child: profileImage != null
                          // Always prefer the locally picked file for instant feedback
                          ? Image.file(
                              profileImage!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                          : (_localAvatarPath != null &&
                                  _localAvatarPath!.isNotEmpty &&
                                  File(_localAvatarPath!).existsSync())
                              ? Image.file(
                                  File(_localAvatarPath!),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                          : (_remoteAvatarUrl != null && _remoteAvatarUrl!.isNotEmpty)
                              ? Image.network(
                                  _bustedUrl(_remoteAvatarUrl!),
                                  key: ValueKey('profile_avatar_$_avatarVersion'),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 50,
                                ),
                    ),
                  ),
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Center(
              child: Text(
                _loadingProfile ? '…' : (displayName.isEmpty ? '—' : displayName),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "Edit Profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Name
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Name",
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 🔹 Email
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: "Email Address",
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 🔹 Nationality
            DropdownButtonFormField<String>(
              initialValue: dropdownNationalityValue,
              decoration: InputDecoration(
                hintText: "Nationality",
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: nationalities.map((String nationality) {
                return DropdownMenuItem<String>(
                  value: nationality,
                  child: Text(nationality),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedNationality = value),
            ),

            const SizedBox(height: 18),

            // 🔹 Password
            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration: InputDecoration(
                hintText: "Create a password",
                suffixIcon: IconButton(
                  icon: Icon(hidePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 🔹 Confirm Password
            TextField(
              controller: confirmPasswordController,
              obscureText: hideConfirmPassword,
              decoration: InputDecoration(
                hintText: "Confirm password",
                suffixIcon: IconButton(
                  icon: Icon(hideConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => hideConfirmPassword = !hideConfirmPassword),
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Save"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
