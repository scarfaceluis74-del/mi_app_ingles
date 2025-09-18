// main.dart
// Flutter English Learning App

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isPremium = prefs.getBool('isPremium') ?? false;
  runApp(MyApp(isPremium: isPremium));
}

class MyApp extends StatelessWidget {
  final bool isPremium;
  const MyApp({super.key, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(isPremium),
      child: MaterialApp(
        title: 'Easy English',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  bool _isPremium;
  AppState(this._isPremium);
  bool get isPremium => _isPremium;

  void unlockPremium() async {
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', true);
    notifyListeners();
  }
}

class Lesson {
  final String title;
  final String content;
  final bool premium;
  Lesson({required this.title, required this.content, this.premium = false});
}

final sampleLessons = [
  Lesson(title: 'Greetings', content: 'Hello\nHi\nGood morning'),
  Lesson(title: 'Numbers', content: 'One, Two, Three, Four'),
  Lesson(title: 'Common verbs (VIP)', content: 'To be, To have, To go', premium: true),
  Lesson(title: 'Phrases (VIP)', content: 'How are you?\nI am fine', premium: true),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy English'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            ),
            tooltip: 'Zona VIP',
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('Lecciones', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...sampleLessons.map((l) => LessonCard(lesson: l)),
          const SizedBox(height: 20),
          const Divider(),
          const Text('Practica', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
            icon: const Icon(Icons.quiz),
            label: const Text('Comenzar práctica rápida'),
          ),
          const SizedBox(height: 24),
          if (appState.isPremium)
            Card(
              color: Colors.amber[50],
              child: ListTile(
                leading: const Icon(Icons.verified, color: Colors.orange),
                title: const Text('VIP activo'),
                subtitle: const Text('Gracias por apoyar el contenido premium!'),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Zona VIP cerrada'),
                subtitle: const Text('Compra acceso VIP para lecciones y prácticas avanzadas'),
                trailing: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                    child: const Text('Abrir')),
              ),
            )
        ],
      ),
    );
  }
}

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  const LessonCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final isPremium = Provider.of<AppState>(context).isPremium;
    final locked = lesson.premium && !isPremium;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(lesson.title),
        subtitle: Text(lesson.premium ? 'Contenido VIP' : 'Gratis'),
        trailing: locked ? const Icon(Icons.lock) : const Icon(Icons.arrow_forward),
        onTap: () {
          if (locked) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Contenido VIP'),
                content: const Text('Esta lección es parte de la Zona VIP. ¿Quieres abrirla?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                      },
                      child: const Text('Ver VIP'))
                ],
              ),
            );
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson)));
        },
      ),
    );
  }
}

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final FlutterTts tts = FlutterTts();

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.9);
    await tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.lesson.content, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                    onPressed: () => _speak(widget.lesson.content),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Escuchar')),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PracticeScreen(text: widget.lesson.content))),
                    icon: const Icon(Icons.record_voice_over),
                    label: const Text('Practicar')),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class PracticeScreen extends StatelessWidget {
  final String text;
  const PracticeScreen({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practicar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lee en voz alta el siguiente texto y compara:'),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text('-> Aquí podrías integrar reconocimiento de voz para comparar pronunciación.'),
          ],
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _questions = [
    {
      'q': 'How do you say "Hola" in English?',
      'options': ['Hello', 'Bye', 'Thanks'],
      'a': 0
    },
    {
      'q': 'Choose the correct: "___ you?"',
      'options': ['How are', 'What is', 'Who am'],
      'a': 0
    }
  ];

  int _index = 0;
  int _score = 0;

  void _answer(int i) {
    if (_questions[_index]['a'] == i) _score++;
    setState(() {
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= _questions.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Puntuación: $_score / ${_questions.length}', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Volver'))
            ],
          ),
        ),
      );
    }

    final q = _questions[_index];

    return Scaffold(
      appBar: AppBar(title: const Text('Práctica')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pregunta ${_index + 1} / ${_questions.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(q['q'] as String, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            ...List.generate((q['options'] as List).length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  onPressed: () => _answer(i),
                  child: Text((q['options'] as List)[i]),
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Zona VIP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Acceso VIP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Las lecciones y prácticas avanzadas estarán desbloqueadas con VIP.'),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                title: const Text('Paquete VIP mensual'),
                subtitle: const Text('Acceso completo a contenido premium'),
                trailing: ElevatedButton(
                  onPressed: appState.isPremium
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Confirmar compra (simulada)'),
                              content: const Text('Esto simula una compra. En producción use in_app_purchase o RevenueCat.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pagar'))
                              ],
                            ),
                          );

                          if (confirm == true) {
                            appState.unlockPremium();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('VIP activado (simulado)')));
                          }
                        },
                  child: Text(appState.isPremium ? 'Activo' : 'Comprar'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('NOTA: Para publicar en Play Store/App Store debes integrar pagos nativos y seguir sus políticas.'),
          ],
        ),
      ),
    );
  }
}

