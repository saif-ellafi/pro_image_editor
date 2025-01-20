// Flutter imports:
import 'package:flutter/widgets.dart';

/// A custom widget that reacts to stream updates.
///
/// This class extends [StatelessWidget] and provides a generic reactive widget
/// that updates its content based on changes emitted by a specified stream.
class ReactiveWidget<T extends Widget> extends StatelessWidget {
  /// Creates an instance of [ReactiveWidget].
  ///
  /// The constructor initializes the widget with a builder function and a
  /// stream. The builder function is used to create the widget's content,
  /// which is updated in response to changes in the stream.
  ///
  /// Example:
  /// ```
  /// ReactiveWidget<Text>(
  ///   builder: (context) => Text('Reactive Content'),
  ///   stream: myUpdateStream,
  /// )
  /// ```
  const ReactiveWidget({
    super.key,
    required this.builder,
    required this.stream,
  });

  /// A builder function to create the widget content.
  ///
  /// This function is called to build the widget based on the current context
  /// and any changes in the stream.
  final T Function(BuildContext context) builder;

  /// A stream that triggers updates to the widget.
  ///
  /// This [Stream<void>] is used to listen for changes that require the widget
  /// to rebuild, allowing for dynamic updates in response to events.
  final Stream<void> stream;

  /// Builds the widget tree for the reactive custom widget.
  ///
  /// This method constructs a [StreamBuilder] that listens to the specified
  /// stream and uses the builder function to update the widget in response to
  /// stream events.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        return builder(context);
      },
    );
  }
}

// TODO: Remove in version 8.0.0
/// Old version of `ReactiveWidget`.
/// Deprecated: Use `ReactiveWidget` instead.
@Deprecated(
    'Use ReactiveWidget instead. This will be removed in a future release.')
class ReactiveCustomWidget<T extends Widget> extends ReactiveWidget<T> {
  /// Creates an instance of [ReactiveCustomWidget].
  const ReactiveCustomWidget({
    super.key,
    required super.builder,
    required super.stream,
  });
}
