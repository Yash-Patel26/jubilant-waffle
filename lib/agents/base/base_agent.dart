import 'dart:async';
import 'package:flutter/foundation.dart';

/// Status of an agent
enum AgentStatus {
  idle,
  initializing,
  running,
  paused,
  stopped,
  error,
}

/// Priority levels for agent tasks
enum AgentPriority {
  low,
  normal,
  high,
  critical,
}

/// Result of an agent operation
class AgentResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? errorCode;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  AgentResult({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
    this.metadata,
  }) : timestamp = DateTime.now();

  factory AgentResult.success(T data, {Map<String, dynamic>? metadata}) {
    return AgentResult(
      success: true,
      data: data,
      metadata: metadata,
    );
  }

  factory AgentResult.failure(String error, {String? errorCode, Map<String, dynamic>? metadata}) {
    return AgentResult(
      success: false,
      error: error,
      errorCode: errorCode,
      metadata: metadata,
    );
  }

  @override
  String toString() => 'AgentResult(success: $success, data: $data, error: $error)';
}

/// Task that can be executed by an agent
class AgentTask<T> {
  final String id;
  final String name;
  final Future<AgentResult<T>> Function() execute;
  final AgentPriority priority;
  final Duration? timeout;
  final int maxRetries;
  final DateTime createdAt;
  int _retryCount = 0;

  AgentTask({
    required this.id,
    required this.name,
    required this.execute,
    this.priority = AgentPriority.normal,
    this.timeout,
    this.maxRetries = 3,
  }) : createdAt = DateTime.now();

  int get retryCount => _retryCount;

  void incrementRetry() => _retryCount++;

  bool get canRetry => _retryCount < maxRetries;
}

/// Base class for all agents in the system
abstract class BaseAgent {
  final String agentId;
  final String agentName;
  final String agentDescription;

  AgentStatus _status = AgentStatus.idle;
  final List<AgentTask> _taskQueue = [];
  final List<String> _logs = [];
  final Map<String, dynamic> _state = {};
  
  Timer? _healthCheckTimer;
  StreamController<AgentStatus>? _statusController;
  
  // Configuration
  final Duration healthCheckInterval;
  final int maxQueueSize;
  final bool autoRestart;

  BaseAgent({
    required this.agentId,
    required this.agentName,
    required this.agentDescription,
    this.healthCheckInterval = const Duration(minutes: 5),
    this.maxQueueSize = 100,
    this.autoRestart = true,
  }) {
    _statusController = StreamController<AgentStatus>.broadcast();
  }

  // Getters
  AgentStatus get status => _status;
  List<String> get logs => List.unmodifiable(_logs);
  Map<String, dynamic> get state => Map.unmodifiable(_state);
  Stream<AgentStatus> get statusStream => _statusController!.stream;
  int get pendingTasks => _taskQueue.length;

  /// Initialize the agent
  Future<void> initialize() async {
    if (_status == AgentStatus.running) return;
    
    _setStatus(AgentStatus.initializing);
    _log('Initializing $agentName...');
    
    try {
      await onInitialize();
      _startHealthCheck();
      _setStatus(AgentStatus.running);
      _log('$agentName initialized successfully');
    } catch (e, stackTrace) {
      _setStatus(AgentStatus.error);
      _log('Failed to initialize $agentName: $e');
      if (kDebugMode) {
        print('$agentName initialization error: $e\n$stackTrace');
      }
      rethrow;
    }
  }

  /// Shutdown the agent
  Future<void> shutdown() async {
    _log('Shutting down $agentName...');
    _healthCheckTimer?.cancel();
    
    try {
      await onShutdown();
      _setStatus(AgentStatus.stopped);
      _log('$agentName shut down successfully');
    } catch (e) {
      _log('Error during shutdown: $e');
    }
  }

  /// Pause the agent
  void pause() {
    if (_status == AgentStatus.running) {
      _setStatus(AgentStatus.paused);
      _log('$agentName paused');
    }
  }

  /// Resume the agent
  void resume() {
    if (_status == AgentStatus.paused) {
      _setStatus(AgentStatus.running);
      _log('$agentName resumed');
      _processQueue();
    }
  }

  /// Add a task to the queue
  Future<AgentResult<T>> enqueueTask<T>(AgentTask<T> task) async {
    if (_taskQueue.length >= maxQueueSize) {
      return AgentResult.failure(
        'Task queue is full',
        errorCode: 'QUEUE_FULL',
      );
    }

    _taskQueue.add(task);
    _log('Task ${task.name} added to queue');
    
    // Process immediately if agent is running
    if (_status == AgentStatus.running) {
      return await _executeTask(task);
    }
    
    return AgentResult.failure(
      'Agent is not running',
      errorCode: 'AGENT_NOT_RUNNING',
    );
  }

  /// Execute a task immediately
  Future<AgentResult<T>> executeImmediate<T>(AgentTask<T> task) async {
    if (_status != AgentStatus.running) {
      return AgentResult.failure(
        'Agent is not running',
        errorCode: 'AGENT_NOT_RUNNING',
      );
    }
    
    return await _executeTask(task);
  }

  /// Process the task queue
  Future<void> _processQueue() async {
    while (_taskQueue.isNotEmpty && _status == AgentStatus.running) {
      // Sort by priority
      _taskQueue.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      
      final task = _taskQueue.removeAt(0);
      await _executeTask(task);
    }
  }

  /// Execute a single task with retry logic
  Future<AgentResult<T>> _executeTask<T>(AgentTask<T> task) async {
    _log('Executing task: ${task.name}');
    
    try {
      final result = await (task.timeout != null
          ? task.execute().timeout(task.timeout!)
          : task.execute());
      
      if (result.success) {
        _log('Task ${task.name} completed successfully');
      } else {
        _log('Task ${task.name} failed: ${result.error}');
        
        if (task.canRetry) {
          task.incrementRetry();
          _log('Retrying task ${task.name} (attempt ${task.retryCount}/${task.maxRetries})');
          return await _executeTask(task);
        }
      }
      
      return result;
    } on TimeoutException {
      _log('Task ${task.name} timed out');
      
      if (task.canRetry) {
        task.incrementRetry();
        return await _executeTask(task);
      }
      
      return AgentResult.failure(
        'Task timed out',
        errorCode: 'TIMEOUT',
      );
    } catch (e) {
      _log('Task ${task.name} error: $e');
      
      if (task.canRetry) {
        task.incrementRetry();
        return await _executeTask(task);
      }
      
      return AgentResult.failure(
        e.toString(),
        errorCode: 'EXECUTION_ERROR',
      );
    }
  }

  /// Start periodic health checks
  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(healthCheckInterval, (_) async {
      await _performHealthCheck();
    });
  }

  /// Perform health check
  Future<void> _performHealthCheck() async {
    try {
      final isHealthy = await checkHealth();
      
      if (!isHealthy && autoRestart) {
        _log('Health check failed, attempting restart...');
        await shutdown();
        await initialize();
      }
    } catch (e) {
      _log('Health check error: $e');
    }
  }

  /// Set agent status and notify listeners
  void _setStatus(AgentStatus newStatus) {
    _status = newStatus;
    _statusController?.add(newStatus);
  }

  /// Log a message
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] [$agentName] $message';
    _logs.add(logEntry);
    
    // Keep only last 1000 logs
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }
    
    if (kDebugMode) {
      print(logEntry);
    }
  }

  /// Update agent state
  void updateState(String key, dynamic value) {
    _state[key] = value;
  }

  /// Get state value
  T? getState<T>(String key) {
    return _state[key] as T?;
  }

  /// Clear agent state
  void clearState() {
    _state.clear();
  }

  /// Get agent info
  Map<String, dynamic> getInfo() {
    return {
      'id': agentId,
      'name': agentName,
      'description': agentDescription,
      'status': _status.name,
      'pending_tasks': _taskQueue.length,
      'logs_count': _logs.length,
    };
  }

  /// Dispose resources
  void dispose() {
    _healthCheckTimer?.cancel();
    _statusController?.close();
  }

  // Abstract methods to be implemented by subclasses
  
  /// Called during agent initialization
  Future<void> onInitialize();
  
  /// Called during agent shutdown
  Future<void> onShutdown();
  
  /// Check if the agent is healthy
  Future<bool> checkHealth();
  
  /// Get agent capabilities
  List<String> getCapabilities();
}
