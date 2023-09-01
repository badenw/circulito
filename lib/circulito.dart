import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/circulito_painter.dart';
import 'src/circulito_section.dart';
import 'src/utils/utils.dart';

export 'src/circulito_section.dart';
export 'src/utils/utils.dart';

/// Circulito is a widget wraps the CirculitoPainter class
/// to be used properly.
///
/// Each section has a percentage and a color.
class Circulito extends StatelessWidget {
  /// The sections to be painted
  ///
  /// Each section has a percentage and a color.
  final List<CirculitoSection> sections;

  /// The maximum size the widget can grow inside its parent.
  ///
  /// If any of the sizes (width or height) of the parent widget are smaller
  /// than this size, the widget will be shrinked to fit the parent.
  ///
  /// Cannot be lower or equal than zero and lower or equal than [strokeWidth].
  final double maxSize;

  /// The padding to be applied to the widget when the parent widget is
  /// bigger or equal than the widget itself.
  final EdgeInsets? padding;

  /// The background color of the wheel to be painted.
  ///
  /// If null, no background will be painted.
  final Color? backgroundColor;

  /// The width of the stroke.
  ///
  /// Cannot be lower or equal than zero and higher than [maxSize].
  final double strokeWidth;

  /// Whether the widget should be centered or not inside the parent widget.
  ///
  /// On parents with infinite sizes like `Column` or `Row`, this property has
  /// no significant effect.
  final bool isCentered;

  /// Determines the shape of the stroke endings.
  ///
  /// Could be `Butt` or `Round`. Default to `Round`.
  final CirculitoStrokeCap strokeCap;

  /// Determines the start point of the wheel.
  ///
  /// Could be `top`, `bottom`, `left` or `right`. Default to `top`.
  final StartPoint startPoint;

  /// Determines the direction of the wheel.
  ///
  /// Could be `clockwise` or `counterClockwise`. Default to `clockwise`.
  final CirculitoDirection direction;

  /// The widget to be shown over the wheel.
  ///
  /// If a `widget` is provided, a `Stack` widget is going to be created and
  /// the [child] widget is going to be placed over the wheel. If no widget
  /// is provided, `Circulito` will be return as it is.
  ///
  /// Easily Center the child wrapping it in a `Center` widget like this:
  /// ```dart
  /// Circulito(
  /// ...
  /// child: Center(child: Text('$value'%)),
  /// )
  /// ```
  final Widget? child;

  /// Determines the type of the value of each section.
  ///
  /// Could be `percentage` or `amount`. Default to `percentage`.
  ///
  /// If [SectionValueType.percentage] is selected, the value of each section
  /// will be interpreted as a percentage of the total value of all sections.
  /// Value must be **between** `0` and `1`. For example:
  /// ```dart
  /// sectionValueType: SectionValueType.percentage,
  /// sections:[
  ///   CirculitoSection(color: Colors.blue, value: 0.45),
  ///   CirculitoSection(color: Colors.pink, value: 0.55),
  /// ]
  /// ```
  ///
  /// If [SectionValueType.amount] is selected, the percentage of the wheel to be painted
  /// is going to be calculated by dividing the each value by the sum
  /// of all the values. For example
  /// ```dart
  /// sectionValueType: SectionValueType.amount,
  /// sections:[
  ///   CirculitoSection(color: Colors.blue, value: 450),
  ///   CirculitoSection(color: Colors.pink, value: 550),
  /// ]
  /// ```
  final SectionValueType sectionValueType;

  Circulito({
    super.key,
    required this.sections,
    required this.maxSize,
    this.child,
    this.padding,
    this.backgroundColor,
    this.strokeWidth = 20,
    this.isCentered = true,
    this.startPoint = StartPoint.top,
    this.direction = CirculitoDirection.clockwise,
    this.strokeCap = CirculitoStrokeCap.round,
    this.sectionValueType = SectionValueType.percentage,
  })  : assert(strokeWidth > 0, "[strokeWidth] must be a positive value"),
        assert(maxSize > 0, "[maxSize] must be a positive value"),
        assert(
            maxSize > strokeWidth,
            "[maxSize] cannot be lower or equal than [strokeWidth],"
            "otherwise, nothing will be drawn on screen.");

  final StreamController<int> hoveredIndexController =
      StreamController<int>.broadcast();

  @override
  Widget build(BuildContext context) {
    Widget mainWidget = StreamBuilder<int>(
        stream: hoveredIndexController.stream,
        builder: (_, snapshot) {
          final hoveredIndex = snapshot.data ?? -1;

          return CustomPaint(
              painter: CirculitoPainter(
            maxsize: maxSize,
            sections: sections,
            direction: direction,
            strokeCap: strokeCap,
            isCentered: isCentered,
            selectedIndex: hoveredIndex,
            startPoint: startPoint,
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor,
            sectionValueType: sectionValueType,
          ));
        });

    if (padding != null) {
      mainWidget = Padding(padding: padding!, child: mainWidget);
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        // For fixed sizes, just return the widget.
        // if (maxWidth.isFinite && maxHeight.isFinite) return mainWidget;
        if (maxWidth.isFinite && maxHeight.isFinite) {
          return _Circulito(
            sizeToDraw: min(maxWidth, maxHeight),
            mainWidget: mainWidget,
            sections: sections,
            isCentered: isCentered,
            hoveredIndexController: hoveredIndexController,
            isInfiniteSizedParent: false,
            strokeWidth: strokeWidth,
            maxsize: maxSize,
            startPoint: startPoint,
            direction: direction,
            padding: padding,
            child: child,
          );
        }

        // For infinite sizes, it is necesary shrink the widget to fit the parent.
        final outerStrokeWidth = strokeWidth / 2;
        final maxAvailableSize = min(maxWidth, maxHeight);

        var sizeToDraw = min(maxSize, maxAvailableSize);
        sizeToDraw -= outerStrokeWidth;

        return _Circulito(
          sizeToDraw: sizeToDraw,
          mainWidget: mainWidget,
          hoveredIndexController: hoveredIndexController,
          sections: sections,
          strokeWidth: strokeWidth,
          isCentered: isCentered,
          padding: padding,
          direction: direction,
          startPoint: startPoint,
          isInfiniteSizedParent: true,
          maxsize: maxSize,
          child: child,
        );
      },
    );

    // return mainWidget;
  }
}

/// Wraps the main widget and the child widget.
// ignore: must_be_immutable
class _Circulito extends StatelessWidget {
  _Circulito({
    required this.sizeToDraw,
    required this.mainWidget,
    required this.maxsize,
    required this.isCentered,
    required this.isInfiniteSizedParent,
    required this.sections,
    required this.strokeWidth,
    required this.hoveredIndexController,
    required this.direction,
    required this.startPoint,
    this.padding,
    this.child,
  });

  final double sizeToDraw;
  final Widget mainWidget;
  final double maxsize;
  final bool isCentered;
  final bool isInfiniteSizedParent;
  final List<CirculitoSection> sections;
  final double strokeWidth;
  final StreamController<int> hoveredIndexController;
  final CirculitoDirection direction;
  final EdgeInsets? padding;
  StartPoint startPoint;
  final Widget? child;

  var _index = -1;

  @override
  Widget build(BuildContext context) {
    final wrappedMainWidget = SizedBox(
      width: sizeToDraw,
      height: sizeToDraw,
      child: MouseRegion(
        onHover: onPointerHover,
        onExit: onPointerExit,
        child: mainWidget,
      ),
    );

    if (child == null) return wrappedMainWidget;

    Widget childToSHow = SizedBox(
      width: min(maxsize, sizeToDraw),
      height: min(maxsize, sizeToDraw),
      child: child,
    );

    if (!isInfiniteSizedParent) {
      childToSHow = Center(child: childToSHow);
    }

    return Stack(
      children: [
        SizedBox(
          width: sizeToDraw,
          height: sizeToDraw,
          child: wrappedMainWidget,
        ),
        childToSHow,
      ],
    );
  }

  /// Handles the hover event.
  void onPointerHover(PointerHoverEvent event) {
    final valueTotal = Utils.getSectionsTotalValue(sections);
    final hoverPosition = event.localPosition;
    final halfSizeToDraw = sizeToDraw / 2;
    final centerOffset = Offset(halfSizeToDraw, halfSizeToDraw);

    /// Get distance from center to approximate the hover position.
    final distance = Utils.getHoverDistanceFromCenter(
      hoverPosition,
      centerOffset,
    );

    // If the hover position is too much inside the wheel, return.
    final diameter = min(maxsize, sizeToDraw) / 2;
    if (distance <= (diameter - strokeWidth) ||
        distance >= (diameter + (strokeWidth))) {
      if (_index != -1) {
        _index = -1;

        hoveredIndexController.add(_index);
      }

      return;
    }
    final angle = Utils.calculateHoverAngle(
      hoverPosition,
      centerOffset,
      halfSizeToDraw,
      CirculitoDirection.clockwise,
      startPoint,
    );

    var sectionIndex = Utils.determineHoverSection(valueTotal, angle, sections);

    // Only update stream if the section has changed.
    if (sectionIndex != _index) {
      _index = sectionIndex;
      hoveredIndexController.add(sectionIndex);
    }
  }

  // Handles the exit event.
  void onPointerExit(PointerExitEvent event) {
    // Remove Selection.
    if (_index != -1) {
      _index = -1;
      hoveredIndexController.add(_index);
    }
  }
}
