import 'package:flutter/material.dart';
import 'package:smartlearn/models/certificate_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlearn/utils/constants.dart';

class ManageCertificatesScreen extends StatefulWidget {
  const ManageCertificatesScreen({super.key});

  @override
  State<ManageCertificatesScreen> createState() =>
      _ManageCertificatesScreenState();
}

class _ManageCertificatesScreenState extends State<ManageCertificatesScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<CertificateModel> _certificates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    try {
      final event = await _database
          .child(AppConstants.certificatesCollection)
          .once();
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        final List<CertificateModel> list = [];
        map.forEach((key, value) {
          final Map<String, dynamic> data = (value as Map).map(
            (k, v) => MapEntry(k.toString(), v),
          );
          list.add(CertificateModel.fromMap(data, key.toString()));
        });
        setState(() {
          _certificates = list;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certificates oversight')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _certificates.isEmpty
          ? const Center(child: Text('No certificates issued yet'))
          : ListView.builder(
              itemCount: _certificates.length,
              itemBuilder: (context, index) {
                final cert = _certificates[index];
                return ListTile(
                  leading: const Icon(Icons.verified, color: Colors.blue),
                  title: Text('${cert.userName} - ${cert.concept}'),
                  subtitle: Text(
                    'Issued: ${cert.earnedAt.toLocal().toString().split(' ')[0]}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () {
                      // TODO: Open publicUrl in browser
                    },
                  ),
                );
              },
            ),
    );
  }
}
