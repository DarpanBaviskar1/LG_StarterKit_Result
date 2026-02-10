import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lg_controller/services/agent_service.dart';
import 'package:lg_controller/src/features/home/data/kml_service.dart';

class KmlAgentScreen extends ConsumerStatefulWidget {
  const KmlAgentScreen({super.key});

  @override
  ConsumerState<KmlAgentScreen> createState() => _KmlAgentScreenState();
}

class _KmlAgentScreenState extends ConsumerState<KmlAgentScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _kmlEditController = TextEditingController();
  String _generatedKml = '';
  bool _isLoading = false;
  bool _isEditing = false;
  final AgentService _agentService = AgentService();

  @override
  void dispose() {
    _promptController.dispose();
    _kmlEditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KML Agent'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Describe what you want to see on LG:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _promptController,
                      decoration: InputDecoration(
                        hintText: 'E.g., "Fly to Eiffel Tower" or "Tour: Paris, Rome, Athens"',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabled: !_isLoading,
                      ),
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generateKml,
                      icon: const Icon(Icons.auto_awesome),
                      label: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Generate KML'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick examples
            if (_generatedKml.isEmpty && !_isLoading) ...[
              const Text(
                'Quick Examples:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildExampleChip('Fly to Taj Mahal'),
                  _buildExampleChip('Fly to Eiffel Tower'),
                  _buildExampleChip('Tour: London, Paris, Rome'),
                  _buildExampleChip('Show earthquakes in Japan'),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Loading state
            if (_isLoading) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Generating KML with Gemini...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Generated KML section
            if (_generatedKml.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Generated KML',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  if (!_isEditing)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _enterEditMode,
                      tooltip: 'Edit KML',
                    ),
                  if (_isEditing)
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: _exitEditMode,
                      tooltip: 'Save changes',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_isEditing)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _generatedKml,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _kmlEditController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelText: 'Edit KML',
                      ),
                      minLines: 10,
                      maxLines: 20,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Action buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _sendToLiquidGalaxy,
                    icon: const Icon(Icons.send),
                    label: const Text('Send to LG'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _playTour,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play Tour'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.content_copy),
                    label: const Text('Copy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _clearKml,
                    icon: const Icon(Icons.delete),
                    label: const Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _promptController.text = text;
        _generateKml();
      },
      avatar: const Icon(Icons.lightbulb, size: 16),
    );
  }

  Future<void> _generateKml() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedKml = '';
      _isEditing = false;
    });

    try {
      final kml = await _agentService.generateKmlFromPrompt(prompt);
      if (!mounted) return;

      setState(() {
        _generatedKml = kml;
        _kmlEditController.text = kml;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
      _kmlEditController.text = _generatedKml;
    });
  }

  void _exitEditMode() {
    setState(() {
      _generatedKml = _kmlEditController.text;
      _isEditing = false;
    });
  }

  Future<void> _sendToLiquidGalaxy() async {
    if (_generatedKml.isEmpty) return;

    try {
      final kmlService = ref.read(kmlServiceProvider);
      await kmlService.sendKmlToMaster(_generatedKml);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ KML sent to Liquid Galaxy')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    }
  }

  Future<void> _playTour() async {
    if (_generatedKml.isEmpty) return;

    try {
      final tourName = _extractTourName(_generatedKml);
      if (tourName == null || tourName.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tour name found in KML')),
        );
        return;
      }

      final kmlService = ref.read(kmlServiceProvider);
      await kmlService.playTour(tourName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playing tour: $tourName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Play failed: $e')),
      );
    }
  }

  void _copyToClipboard() {
    if (_generatedKml.isEmpty) return;

    Clipboard.setData(ClipboardData(text: _generatedKml));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Copied to clipboard')),
    );
  }

  void _clearKml() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear KML?'),
        content: const Text('Are you sure you want to clear the generated KML?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _generatedKml = '';
                _kmlEditController.clear();
                _isEditing = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ KML cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String? _extractTourName(String kml) {
    final tourMatch = RegExp(
      r'<gx:Tour>[\s\S]*?<name>([^<]+)</name>',
      caseSensitive: false,
    ).firstMatch(kml);
    if (tourMatch != null) {
      return tourMatch.group(1)?.trim();
    }

    final docMatch = RegExp(
      r'<Document>[\s\S]*?<name>([^<]+)</name>',
      caseSensitive: false,
    ).firstMatch(kml);
    return docMatch?.group(1)?.trim();
  }
}
