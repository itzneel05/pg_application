import 'package:flutter/material.dart';
import 'package:pg_application/animations/routeanimation.dart';
import 'package:pg_application/screens/edit_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pg_application/screens/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
class Profile extends StatefulWidget {
  const Profile({super.key});
  @override
  State<Profile> createState() => _ProfileState();
}
class _ProfileState extends State<Profile> {
  bool darkMode = false;
  bool notifications = false;
  // Add migration guard and helper to copy legacy user doc to users/{uid}
  bool _attemptedMigration = false;
  Future<void> _migrateLegacyUserDoc(String uid) async {
    try {
      final users = FirebaseFirestore.instance.collection('users');
      final q = await users.where('authUid', isEqualTo: uid).limit(1).get();
      if (q.docs.isNotEmpty) {
        final data = q.docs.first.data();
        await users.doc(uid).set(data, SetOptions(merge: true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile restored')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _attemptedMigration = true);
    }
  }
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Login(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }
  Widget _profileHeaderCard() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Not signed in'),
        ),
      );
    }
    final users = FirebaseFirestore.instance.collection('users');
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: users.doc(uid).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Failed to load profile'),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (!snap.hasData || !(snap.data?.exists ?? false)) {
          // Attempt one-time migration from legacy authUid-based doc
          if (!_attemptedMigration) {
            // Schedule migration without rebuilding loops
            Future.microtask(() => _migrateLegacyUserDoc(uid));
          }
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Profile not found'),
            ),
          );
        }
        final data = snap.data!.data()!;
        final fullName = (data['fullName'] as String?)?.trim();
        final email = (data['email'] as String?)?.trim();
        final phone = (data['phoneNumber'] as String?)?.trim();
        final photoUrl = (data['photoUrl'] as String?)?.trim();
        final locationMap = data['location'] as Map<String, dynamic>?;
        final locationLabel = (locationMap?['label'] as String?)?.trim();
        final updatedAt = (data['photoUpdatedAt'] as Timestamp?)?.toDate();
        DateTime? created;
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp) {
          created = createdAt.toDate();
        }
        final fullNameText = (fullName != null && fullName.isNotEmpty)
            ? fullName
            : 'Full name';
        final emailText = (email != null && email.isNotEmpty) ? email : 'Email';
        final phoneText = (phone != null && phone.isNotEmpty)
            ? phone
            : 'Set mobile number';
        final locationText = (locationLabel != null && locationLabel.isNotEmpty)
            ? locationLabel
            : 'Set location';
        final memberSinceText = created != null
            ? 'Member since ${formatMemberSince(created)}'
            : 'Member since —';
        String? avatarUrl;
        if (photoUrl != null && photoUrl.isNotEmpty) {
          final v =
              updatedAt?.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch;
          avatarUrl = '$photoUrl?v=$v';
        }
        return SizedBox(
          width: double.infinity,
          child: Card(
            child: Column(
              children: [
                const SizedBox(height: 22),
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: (avatarUrl != null)
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null)
                      ? Icon(Icons.person, size: 60, color: Colors.grey[500])
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  fullNameText,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  emailText,
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
                if (phone != null && phone.isNotEmpty)
                  Text(
                    "+91$phone",
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pin_drop, size: 22),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        locationText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700], fontSize: 15),
                      ),
                    ),
                  ],
                ),
                Text(
                  memberSinceText,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 201, 226, 253),
            Color.fromARGB(255, 218, 222, 225),
          ],
          stops: [0.0, 0.4],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(62.0),
          child: AppBar(
            elevation: 2.5,
            shadowColor: Colors.black,
            automaticallyImplyLeading: false,
            centerTitle: true,
            backgroundColor: Color.fromRGBO(25, 118, 210, 1),
            title: Text(
              "My Profile",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 370,
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _profileHeaderCard(),
                  SizedBox(height: 27),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('reviews')
                          .where(
                            'userid',
                            isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                          )
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'My Reviews (0)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          );
                        }
                        final count = snapshot.data?.docs.length ?? 0;
                        if (snapshot.connectionState == ConnectionState.waiting && count == 0) {
                          return const SizedBox(
                            height: 20,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        return Text(
                          'My Reviews (${count})',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 7),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where(
                          'userid',
                          isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                        )
                        .limit(2)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Card(
                          elevation: 0.5,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: SizedBox(
                            height: 80,
                            child: Center(
                              child: Text(
                                'Failed to load reviews',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        );
                      }
                      final docs = snapshot.data?.docs ?? const [];
                      if (snapshot.connectionState == ConnectionState.waiting && docs.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (docs.isEmpty) {
                        return Card(
                          elevation: 0.5,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: SizedBox(
                            height: 80,
                            child: Center(
                              child: Text(
                                'No reviews yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('pgRooms')
                                .doc(data['pgdocid'])
                                .get(),
                            builder: (context, pgSnapshot) {
                              String pgName = 'Unknown PG';
                              if (pgSnapshot.hasError) {
                                pgName = 'Unknown PG';
                              } else if (pgSnapshot.hasData && pgSnapshot.data!.exists) {
                                final pgData = pgSnapshot.data!.data() as Map<String, dynamic>;
                                pgName = pgData['name'] ?? 'Unknown PG';
                              }
                              return Card(
                                elevation: 0.5,
                                margin: EdgeInsets.symmetric(vertical: 4),
                                child: SizedBox(
                                  height: 80,
                                  child: ListTile(
                                    title: Text(
                                      pgName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      data['reviewText'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    leading: SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ...List.generate(
                                            5,
                                            (i) => Icon(
                                              Icons.star,
                                              color: i < (data['rating'] as num? ?? 0).toDouble()
                                                  ? Colors.amber
                                                  : Colors.grey[300],
                                              size: 19,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () => _showUserReviews(context),
                    child: Text('View All Reviews'),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.edit, color: Colors.blue),
                          title: Text('Edit Profile'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () {
                            Navigator.push(
                              context,
                              fadeAnimatedRoute(EditProfilePage()),
                            );
                          },
                        ),

                        ListTile(
                          leading: Icon(
                            Icons.rate_review,
                            color: Colors.black54,
                          ),
                          title: Text('My Reviews'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () {
                            _showUserReviews(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.security_outlined,
                            color: Colors.black54,
                          ),
                          title: Text('Privacy & Security'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () async {
                            final url = Uri.parse('https://www.pgfinder.com/privacy-policy');
                            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open privacy policy')),
                                );
                              }
                            }
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.logout, color: Colors.red),
                          title: Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  void _showUserReviews(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Reviews',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('reviews')
                          .where('userid', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading reviews: ${snapshot.error}',
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'You haven\'t written any reviews yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }
                        final reviewDocs = snapshot.data!.docs;
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: reviewDocs.length,
                          itemBuilder: (context, index) {
                            final doc = reviewDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final timestamp = data['createdAt'] as Timestamp?;
                            final timeAgo = timestamp != null
                                ? _getTimeAgo(timestamp.toDate())
                                : 'Recently';
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('pgRooms')
                                  .doc(data['pgdocid'])
                                  .get(),
                              builder: (context, pgSnapshot) {
                                String pgName = 'Unknown PG';
                                if (pgSnapshot.hasData &&
                                    pgSnapshot.data!.exists) {
                                  final pgData =
                                      pgSnapshot.data!.data()
                                          as Map<String, dynamic>;
                                  pgName = pgData['name'] ?? 'Unknown PG';
                                }
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pgName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: List.generate(5, (i) {
                                            return Icon(
                                              Icons.star,
                                              color:
                                                  i <
                                                      (data['rating'] as num)
                                                          .toDouble()
                                                  ? Colors.amber
                                                  : Colors.grey[300],
                                              size: 18,
                                            );
                                          }),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          data['reviewText'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            timeAgo,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }
  String formatMemberSince(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);
}

