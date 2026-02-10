import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:lg_controller/src/features/tour_builder/domain/models/tour.dart';
import 'package:lg_controller/src/features/tour_builder/data/tour_provider.dart';
import 'package:lg_controller/src/features/tour_builder/presentation/tour_builder_screen.dart';

class AISuggestionDialog extends ConsumerStatefulWidget {
  const AISuggestionDialog({super.key});

  @override
  ConsumerState<AISuggestionDialog> createState() =>
      _AISuggestionDialogState();
}

class _AISuggestionDialogState extends ConsumerState<AISuggestionDialog> {
  final _promptController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateTour() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a tour description')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gemini = ref.read(geminiServiceProvider);
      final waypoints =
          await gemini.generateTourSuggestions(_promptController.text);

      if (waypoints.isEmpty) {
        throw Exception('No waypoints generated');
      }

      final tour = Tour(
        id: const Uuid().v4(),
        name: _promptController.text,
        description: 'AI-generated tour',
        waypoints: waypoints,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      Navigator.pop(context);

      // Navigate to builder with the AI-generated tour
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TourBuilderScreen(initialTour: tour),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Tour Suggestion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Describe the tour you want to create.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              labelText: 'E.g., "Roman Empire historical sites"',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 3,
            enabled: !_isLoading,
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Generating tour with AI...'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _generateTour,
          child: const Text('Generate'),
        ),
      ],
    );
  }
}
