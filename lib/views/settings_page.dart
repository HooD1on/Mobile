// lib/views/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
      final settingsViewModel = Provider.of<SettingsViewModel>(context, listen: false);
      settingsViewModel.onSettingsChanged = homeViewModel.onSettingsChanged;
    });
  }

  Widget _buildSlider({
    required String title,
    required IconData icon,
    required double value,
    required Function(BuildContext, double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              Text(
                value.toStringAsFixed(2),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0.0,
            max: 2.0,
            divisions: 40,
            label: value.toStringAsFixed(2),
            onChanged: (value) => onChanged(context, value),
          ),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () {
              Provider.of<SettingsViewModel>(context, listen: false)
                  .resetToDefaults(context);
            },
          ),
        ],
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, settingsViewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Image Processing Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                _buildSlider(
                  title: 'Brightness',
                  icon: Icons.brightness_6,
                  value: settingsViewModel.brightness,
                  onChanged: settingsViewModel.updateBrightness,
                ),

                _buildSlider(
                  title: 'Contrast',
                  icon: Icons.contrast,
                  value: settingsViewModel.contrast,
                  onChanged: settingsViewModel.updateContrast,
                ),

                _buildSlider(
                  title: 'Clarity' ,
                  icon: Icons.blur_on,
                  value: settingsViewModel.clarity,
                  onChanged: settingsViewModel.updateSharpness,
                ),

                _buildSlider(
                  title: 'Noise Reduction',
                  icon: Icons.blur_linear,
                  value: settingsViewModel.noiseReduction,
                  onChanged: settingsViewModel.updateNoiseReduction,
                ),

                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Changes will be applied immediately to the current image.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}