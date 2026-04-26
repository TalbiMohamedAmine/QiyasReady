import 'package:flutter/material.dart';

class CustomizedTestScreen extends StatefulWidget {
  const CustomizedTestScreen({super.key});

  @override
  State<CustomizedTestScreen> createState() => _CustomizedTestScreenState();
}

class _CustomizedTestScreenState extends State<CustomizedTestScreen> {
  final List<String> _selectedChapters = [];
  String _difficulty = 'Medium';
  int _questionCount = 10;

  final List<String> _chapters = ['Arithmetic', 'Geometry', 'Algebra', 'Statistics', 'Logic'];
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Customized Tests')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generate a targeted practice session.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            
            Text('Select Chapters', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _chapters.map((chapter) {
                final isSelected = _selectedChapters.contains(chapter);
                return FilterChip(
                  label: Text(chapter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedChapters.add(chapter);
                      } else {
                        _selectedChapters.remove(chapter);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            Text('Select Difficulty', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: _difficulties.map((diff) => ButtonSegment(value: diff, label: Text(diff))).toList(),
              selected: {_difficulty},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _difficulty = newSelection.first;
                });
              },
            ),
            
            const SizedBox(height: 24),
            Text('Number of Questions: $_questionCount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Slider(
              value: _questionCount.toDouble(),
              min: 5,
              max: 50,
              divisions: 9,
              label: _questionCount.toString(),
              onChanged: (double value) {
                setState(() {
                  _questionCount = value.toInt();
                });
              },
            ),
            
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _selectedChapters.isEmpty ? null : () {
                // TODO: Hook up to AdaptivePractice service with these filters
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Starting customized test with $_questionCount questions.')),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Generate & Start Practice'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
