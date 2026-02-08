import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final bool autoFocus;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Buscar...',
    required this.onSearch,
    this.onClear,
    this.autoFocus = false,
    this.controller,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
    if (widget.onClear != null) {
      widget.onClear!();
    }
    FocusScope.of(context).unfocus(); // UX: Ocultar teclado al limpiar
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // UX: Sombra más suave y moderna (menos pesada que el Card por defecto)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TÍTULO CON ESTILO REFINADO
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.manage_search_rounded, color: Colors.orange, size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Panel de Filtros',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF181B35),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CAMPO DE BÚSQUEDA TÁCTIL
            TextField(
              controller: _controller,
              autofocus: widget.autoFocus,
              style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
                filled: true,
                fillColor: const Color(0xFFF5F7FA), // Gris muy sutil para profundidad
                prefixIcon: const Icon(Icons.search, color: Colors.orange, size: 20),
                suffixIcon: _hasText
                    ? IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                  onPressed: _clearSearch,
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: widget.onSearch,
              onSubmitted: widget.onSearch,
              textInputAction: TextInputAction.search,
            ),

            const SizedBox(height: 12),

            // BOTÓN DE BÚSQUEDA INTEGRADO
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSearch(_controller.text);
                  FocusScope.of(context).unfocus(); // UX: Cerrar teclado al buscar
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'APLICAR BÚSQUEDA',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),

            // INDICADOR DINÁMICO
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _hasText
                  ? Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_list_alt, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Filtrando por: "${_controller.text}"',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}