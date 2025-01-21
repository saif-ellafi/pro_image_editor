// Dart imports:
import 'dart:async';

// Project imports:
import '/core/models/multi_threading/thread_request_model.dart';
import '/core/models/multi_threading/thread_response_model.dart';
import '/shared/utils/unique_id_generator.dart';

/// An abstract class representing a thread (isolate) used for processing tasks.
///
/// This class provides the structure for managing tasks within an isolate,
/// including initializing the isolate, sending data to the isolate, and
/// destroying active tasks.
abstract class Thread {
  /// Constructs a [Thread] with the given [onMessage] callback.
  ///
  /// The constructor generates a unique ID for the thread, initializes the
  /// [readyState] completer, and calls the [init] method to set up the thread.
  Thread({
    required this.onMessage,
    required this.coreNumber,
  }) {
    id = generateUniqueId();
    readyState = Completer();
    init();
  }

  /// The name of the debug thread used in the Pro Image Editor plugin.
  ///
  /// This is a constant string that identifies the thread for debugging
  /// purposes.
  final String debugThreadName = 'PIE-Thread';

  /// A unique id for this thread.
  late String id;

  /// List of IDs of tasks currently being processed by the isolate.
  List<String> activeTaskIds = [];

  /// Number of active tasks currently being processed by the isolate.
  int activeTasks = 0;

  /// Number from the used processor core.
  final int coreNumber;

  /// Callback function for handling messages received from the isolate.
  final Function(ThreadResponse) onMessage;

  /// A completer to track when the thread is ready for communication.
  late Completer<bool> readyState;

  /// Indicates whether the thread is ready for communication.
  bool isReady = false;

  /// Initializes the thread.
  ///
  /// This method should be implemented by subclasses to perform any setup
  /// necessary for the thread.
  void init();

  /// Sends a [ThreadRequest] to the thread for processing.
  ///
  /// [data] - The data to be processed by the thread.
  void send(ThreadRequest data);

  /// Destroys all active tasks in the thread, except the task with the given
  /// [ignoreTaskId].
  ///W
  /// [ignoreTaskId] - The ID of the task that should not be destroyed.
  void destroyActiveTasks(String ignoreTaskId);

  /// Destroys the thread and cleans up any resources.
  ///
  /// This method should be implemented by subclasses to perform any cleanup
  /// necessary when the thread is no longer needed.
  void destroy();
}
