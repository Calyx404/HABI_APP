import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:habi/shared/theme/habi_background.dart';

import 'package:habi/data/account_store.dart';
import 'package:habi/shared/widgets/form_widgets.dart';
import 'package:habi/shared/theme/habi_colors.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key, required this.userName});

  final String userName;

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  bool _isPicking = false;

  Account? get _account => AccountStore.instance.byDisplayName(widget.userName);

  @override
  void initState() {
    super.initState();
  }

  Future<void> _chooseResume() async {
    setState(() => _isPicking = true);
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Choose a PDF resume',
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        windowsOptions: const WindowsOptions(lockParentWindow: true),
        linuxOptions: const LinuxOptions(lockParentWindow: true),
      );
      if (file == null || !mounted) return;

      if (!file.name.toLowerCase().endsWith('.pdf')) {
        showHabiSnack(context, 'Select a PDF file.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        showHabiSnack(
          context,
          'The selected PDF could not be read. Choose it again.',
        );
        return;
      }
      final account = _account;
      if (account == null) {
        showHabiSnack(
          context,
          'Could not find this profile to save the resume.',
        );
        return;
      }
      await AccountStore.instance.saveResume(name: file.name, bytes: bytes);
      if (!mounted) return;
      showHabiSnack(context, '${file.name} saved to your profile.');
      setState(() {});
    } catch (error, stackTrace) {
      debugPrint('Resume PDF picker failed: $error\n$stackTrace');
      if (mounted) {
        showHabiSnack(
          context,
          'Could not open the PDF picker (${error.runtimeType}). Fully restart the app and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _removeResume() async {
    try {
      await AccountStore.instance.removeResume();
      if (!mounted) return;
      setState(() {});
      showHabiSnack(context, 'Resume removed from your profile.');
    } catch (error) {
      if (mounted) {
        showHabiSnack(context, 'Could not remove the resume: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumeName = _account?.resumeName ?? '';
    return Scaffold(
      backgroundColor: HabiColors.navy,
      appBar: AppBar(
        backgroundColor: HabiColors.navy,
        foregroundColor: HabiColors.cream,
        title: Text('Resume'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          HabiBackground(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add a resume to your profile',
                    style: TextStyle(
                      color: HabiColors.cream,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Choose a PDF document. It is stored privately with your profile.',
                    style: TextStyle(color: HabiColors.cream.withAlpha(200)),
                  ),
                  SizedBox(height: 20),
                  if (resumeName.isNotEmpty)
                    Card(
                      color: HabiColors.navyMid.withAlpha(240),
                      child: ListTile(
                        leading: Icon(
                          Icons.description_outlined,
                          color: HabiColors.gold,
                        ),
                        title: Text(
                          resumeName,
                          style: TextStyle(color: HabiColors.cream),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Saved resume',
                          style: TextStyle(
                            color: HabiColors.cream.withAlpha(180),
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove resume',
                          onPressed: _removeResume,
                          icon: Icon(
                            Icons.delete_outline,
                            color: HabiColors.cream,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isPicking ? null : _chooseResume,
                      icon: _isPicking
                          ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.upload_file_outlined),
                      label: Text(
                        resumeName.isEmpty
                            ? 'Choose Resume File'
                            : 'Replace Resume',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: HabiColors.gold,
                        foregroundColor: HabiColors.ink,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Supported format: PDF only',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: HabiColors.cream.withAlpha(170),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
