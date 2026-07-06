import 'package:club_lectura_app/services/api_service.dart';
import 'package:flutter/material.dart';

class ConfigurarLecturaPage extends StatefulWidget {
  final String libro;
  final String tipo;

  const ConfigurarLecturaPage({
    super.key,
    required this.libro,
    this.tipo = "LIBRE",
  });

  @override
  State<ConfigurarLecturaPage> createState() => _ConfigurarLecturaPageState();
}

class _ConfigurarLecturaPageState extends State<ConfigurarLecturaPage> {
  final controllerCapitulos = TextEditingController();

  bool prologo = false;
  bool epilogo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tipo == "OFICIAL"
              ? "📖 Configurar lectura oficial"
              : "📚 Nueva lectura compartida",
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              widget.libro,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              widget.tipo == "OFICIAL"
                  ? "Esta será la conversación oficial del club para esta lectura."
                  : "Configura la conversación para este libro.",
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: controllerCapitulos,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Número de capítulos",
              ),
            ),

            const SizedBox(height: 20),

            CheckboxListTile(
              value: prologo,
              title: const Text("Tiene prólogo"),
              onChanged: (v) {
                setState(() {
                  prologo = v ?? false;
                });
              },
            ),

            CheckboxListTile(
              value: epilogo,
              title: const Text("Tiene epílogo"),
              onChanged: (v) {
                setState(() {
                  epilogo = v ?? false;
                });
              },
            ),

            const Spacer(),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
              ),
              onPressed: () async {
                final capitulos = int.tryParse(controllerCapitulos.text);

                if (capitulos == null || capitulos <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Introduce un número válido")),
                  );
                  return;
                }

                final ok = await ApiService().crearLectura(
                  libro: widget.libro,
                  capitulos: capitulos,
                  prologo: prologo,
                  epilogo: epilogo,
                  tipo: widget.tipo,
                );
                if (!mounted) return;

                if (ok) {
                  await Future.delayed(const Duration(milliseconds: 500));

                  if (!mounted) return;

                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.check),
              label: const Text("Crear conversación"),
            ),
          ],
        ),
      ),
    );
  }
}
