import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}
class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _picker = ImagePicker();
  bool _uploadingPhoto = false;
  String? _photoUrl;
  bool _loading = true;
  bool _saving = false;
  DocumentReference<Map<String, dynamic>>? _userDocRef;
  @override
  void initState() {
    super.initState();
    _loadFromFirestore();
  }
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }
  Future<void> _loadFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _loading = false);
        return;
      }
      final users = FirebaseFirestore.instance.collection('users');
      final docRef = users.doc(uid);
      final doc = await docRef.get();
      if (doc.exists) {
        _userDocRef = docRef;
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = (data['fullName'] as String?)?.trim() ?? '';
        _emailController.text = (data['email'] as String?)?.trim() ?? '';
        _phoneController.text = (data['phoneNumber'] as String?)?.trim() ?? '';
        _photoUrl = (data['photoUrl'] as String?)?.trim();
        final loc = data['location'] as Map<String, dynamic>?;
        _cityController.text = (loc?['city'] as String?)?.trim() ?? '';
        _stateController.text = (loc?['state'] as String?)?.trim() ?? '';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  Future<void> _saveChanges() async {
    if (_saving) return;
    if (_userDocRef == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User profile not found')));
      return;
    }
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final hasCity = city.isNotEmpty;
    final hasState = state.isNotEmpty;
    final label = (hasCity && hasState)
        ? '$city, $state'
        : (hasCity ? city : (hasState ? state : null));
    final update = <String, dynamic>{
      'fullName': fullName.isNotEmpty ? fullName : null,
      'email': email.isNotEmpty ? email : null,
      'phoneNumber': phone.isNotEmpty ? phone : null,
      'location': {
        'label': label,
        'city': hasCity ? city : null,
        'state': hasState ? state : null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    };
    setState(() => _saving = true);
    try {
      await _userDocRef!.set(update, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  Future<void> _pickAndUploadAvatar() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Not signed in';
      final uid = user.uid;
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.gallery, 
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xfile == null) return;
      setState(() => _uploadingPhoto = true);
      final storage = Supabase.instance.client.storage.from(
        'avatars',
      ); 
      final path = 'users/$uid/profile.jpg'; 
      await storage.upload(
        path,
        File(xfile.path),
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
          cacheControl: '3600',
        ),
      );
      final publicUrl = storage.getPublicUrl(path);
      final users = FirebaseFirestore.instance.collection('users');
      final q = await users.where('authUid', isEqualTo: uid).limit(1).get();
      if (q.docs.isNotEmpty) {
        await q.docs.first.reference.set({
          'photoUrl': publicUrl,
          'photoUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      setState(() {
        _photoUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Photo update failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62.0),
        child: AppBar(
          elevation: 2.5,
          shadowColor: Colors.black,
          centerTitle: true,
          backgroundColor: const Color.fromRGBO(25, 118, 210, 1),
          title: const Text(
            "Edit Profile",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Container(
                  width: 370,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          _avatarFromStream(),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _uploadingPhoto
                                ? null
                                : _pickAndUploadAvatar,
                            child: _uploadingPhoto
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Change Photo',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email Address",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: "City",
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _stateController,
                        decoration: InputDecoration(
                          labelText: "State",
                          prefixIcon: const Icon(Icons.map),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(
                              25,
                              118,
                              210,
                              1,
                            ),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _saving ? null : _saveChanges,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
Widget _avatarFromStream() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, size: 60, color: Colors.grey[400]),
    );
  }
  final users = FirebaseFirestore.instance.collection('users');
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: users.doc(uid).snapshots(),
    builder: (context, snap) {
      String? displayUrl;
      if (snap.hasError) {
        // Fall back to default avatar on error
        displayUrl = null;
      } else if (snap.hasData && snap.data!.exists) {
        final data = snap.data!.data()!;
        final url = (data['photoUrl'] as String?)?.trim();
        final updatedAt = (data['photoUpdatedAt'] as Timestamp?)?.toDate();
        if (url != null && url.isNotEmpty) {
          final v = updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
          displayUrl = '$url?v=$v';
        }
      }
      return CircleAvatar(
        key: ValueKey(displayUrl),
        radius: 44,
        backgroundColor: Colors.grey[300],
        backgroundImage: (displayUrl != null) ? NetworkImage(displayUrl) : null,
        child: (displayUrl == null)
            ? Icon(Icons.person, size: 60, color: Colors.grey[400])
            : null,
      );
    },
  );
}

