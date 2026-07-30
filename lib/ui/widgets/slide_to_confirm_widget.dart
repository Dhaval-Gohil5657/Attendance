import 'package:flutter/material.dart';

class SlideToConfirmWidget extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color sliderColor;
  final Color textColor;
  final VoidCallback onConfirmed;
  final double height;
  final bool isReversed; // false = Left-to-Right, true = Right-to-Left

  const SlideToConfirmWidget({
    super.key,
    required this.text,
    this.icon = Icons.arrow_forward_rounded,
    required this.backgroundColor,
    required this.sliderColor,
    this.textColor = Colors.white,
    required this.onConfirmed,
    this.height = 55.0,
    this.isReversed = false,
  });

  @override
  State<SlideToConfirmWidget> createState() => _SlideToConfirmWidgetState();
}

class _SlideToConfirmWidgetState extends State<SlideToConfirmWidget>
    with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - widget.height;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(color: widget.sliderColor,width: 0.15),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Sliding track fill color
              Positioned(
                left: widget.isReversed ? null : 0,
                right: widget.isReversed ? 0 : null,
                top: 0,
                bottom: 0,
                width: _dragValue + widget.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.sliderColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
              ),

              // Hint text padded so it is never covered by the resting slider button
              Positioned.fill(
                child: Padding(
                  padding: widget.isReversed
                      ? EdgeInsets.only(right: widget.height, left: 12.0)
                      : EdgeInsets.only(left: widget.height, right: 12.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: (1.0 - (_dragValue / maxDrag)).clamp(0.0, 1.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: widget.isReversed
                            ? [
                                Icon(
                                  Icons.keyboard_double_arrow_left_rounded,
                                  color: widget.textColor.withValues(alpha: 0.8),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    widget.text,
                                    style: TextStyle(
                                      color: widget.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      letterSpacing: 1.0,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ]
                            : [
                                Flexible(
                                  child: Text(
                                    widget.text,
                                    style: TextStyle(
                                      color: widget.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      letterSpacing: 1.0,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_double_arrow_right_rounded,
                                  color: widget.textColor.withValues(alpha: 0.8),
                                  size: 18,
                                ),
                              ],
                      ),
                    ),
                  ),
                ),
              ),

              // Draggable Slider Button
              Positioned(
                left: widget.isReversed ? null : _dragValue,
                right: widget.isReversed ? _dragValue : null,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isConfirmed) return;
                    setState(() {
                      final delta = widget.isReversed ? -details.delta.dx : details.delta.dx;
                      _dragValue += delta;
                      _dragValue = _dragValue.clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isConfirmed) return;
                    if (_dragValue >= maxDrag * 0.85) {
                      setState(() {
                        _dragValue = maxDrag;
                        _isConfirmed = true;
                      });
                      widget.onConfirmed();
                      // Reset slider after a short delay
                      Future.delayed(const Duration(milliseconds: 1200), () {
                        if (mounted) {
                          setState(() {
                            _dragValue = 0.0;
                            _isConfirmed = false;
                          });
                        }
                      });
                    } else {
                      // Smooth snap back
                      setState(() {
                        _dragValue = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: widget.height,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.sliderColor,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
