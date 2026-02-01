import 'dart:async';
import 'package:flutter/foundation.dart';
import 'base_agent.dart';

/// Event types for agent lifecycle
enum AgentEvent {
  registered,
  unregistered,
  started,
  stopped,
  paused,
  resumed,
  error,
  healthCheckFailed,
}

/// Agent event data
class AgentEventData {
  final String agentId;
  final AgentEvent event;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AgentEventData({
    required this.agentId,
    required this.event,
    this.metadata,
  }) : timestamp = DateTime.now();
}

/// Central registry for all agents in the system
class AgentRegistry {
  static final AgentRegistry _instance = AgentRegistry._internal();
  factory AgentRegistry() => _instance;
  AgentRegistry._internal();

  final Map<String, BaseAgent> _agents = {};
  final Map<String, List<String>> _agentsByCategory = {};
  final StreamController<AgentEventData> _eventController = 
      StreamController<AgentEventData>.broadcast();

  /// Get all registered agents
  Map<String, BaseAgent> get agents => Map.unmodifiable(_agents);

  /// Get event stream
  Stream<AgentEventData> get events => _eventController.stream;

  /// Register an agent
  void register(BaseAgent agent, {String? category}) {
    if (_agents.containsKey(agent.agentId)) {
      if (kDebugMode) {
        print('Agent ${agent.agentId} is already registered');
      }
      return;
    }

    _agents[agent.agentId] = agent;

    // Add to category if specified
    if (category != null) {
      _agentsByCategory.putIfAbsent(category, () => []);
      _agentsByCategory[category]!.add(agent.agentId);
    }

    _emitEvent(agent.agentId, AgentEvent.registered);

    if (kDebugMode) {
      print('Agent ${agent.agentName} registered with ID: ${agent.agentId}');
    }
  }

  /// Unregister an agent
  Future<void> unregister(String agentId) async {
    final agent = _agents[agentId];
    if (agent == null) return;

    // Shutdown the agent first
    await agent.shutdown();

    // Remove from registry
    _agents.remove(agentId);

    // Remove from categories
    for (final category in _agentsByCategory.keys) {
      _agentsByCategory[category]?.remove(agentId);
    }

    _emitEvent(agentId, AgentEvent.unregistered);

    if (kDebugMode) {
      print('Agent $agentId unregistered');
    }
  }

  /// Get an agent by ID
  T? getAgent<T extends BaseAgent>(String agentId) {
    return _agents[agentId] as T?;
  }

  /// Get agents by category
  List<BaseAgent> getAgentsByCategory(String category) {
    final agentIds = _agentsByCategory[category] ?? [];
    return agentIds
        .map((id) => _agents[id])
        .where((agent) => agent != null)
        .cast<BaseAgent>()
        .toList();
  }

  /// Get agents by status
  List<BaseAgent> getAgentsByStatus(AgentStatus status) {
    return _agents.values.where((agent) => agent.status == status).toList();
  }

  /// Initialize all registered agents
  Future<void> initializeAll() async {
    if (kDebugMode) {
      print('Initializing ${_agents.length} agents...');
    }

    final futures = <Future<void>>[];
    
    for (final agent in _agents.values) {
      futures.add(_initializeAgent(agent));
    }

    await Future.wait(futures);

    if (kDebugMode) {
      print('All agents initialized');
    }
  }

  /// Initialize a single agent with error handling
  Future<void> _initializeAgent(BaseAgent agent) async {
    try {
      await agent.initialize();
      _emitEvent(agent.agentId, AgentEvent.started);
    } catch (e) {
      _emitEvent(agent.agentId, AgentEvent.error, metadata: {'error': e.toString()});
      if (kDebugMode) {
        print('Failed to initialize agent ${agent.agentId}: $e');
      }
    }
  }

  /// Shutdown all agents
  Future<void> shutdownAll() async {
    if (kDebugMode) {
      print('Shutting down ${_agents.length} agents...');
    }

    final futures = <Future<void>>[];
    
    for (final agent in _agents.values) {
      futures.add(_shutdownAgent(agent));
    }

    await Future.wait(futures);

    if (kDebugMode) {
      print('All agents shut down');
    }
  }

  /// Shutdown a single agent with error handling
  Future<void> _shutdownAgent(BaseAgent agent) async {
    try {
      await agent.shutdown();
      _emitEvent(agent.agentId, AgentEvent.stopped);
    } catch (e) {
      if (kDebugMode) {
        print('Error shutting down agent ${agent.agentId}: $e');
      }
    }
  }

  /// Pause all agents
  void pauseAll() {
    for (final agent in _agents.values) {
      agent.pause();
      _emitEvent(agent.agentId, AgentEvent.paused);
    }
  }

  /// Resume all agents
  void resumeAll() {
    for (final agent in _agents.values) {
      agent.resume();
      _emitEvent(agent.agentId, AgentEvent.resumed);
    }
  }

  /// Get health status of all agents
  Future<Map<String, bool>> getHealthStatus() async {
    final healthStatus = <String, bool>{};
    
    for (final entry in _agents.entries) {
      try {
        healthStatus[entry.key] = await entry.value.checkHealth();
      } catch (e) {
        healthStatus[entry.key] = false;
      }
    }
    
    return healthStatus;
  }

  /// Get summary of all agents
  Map<String, dynamic> getSummary() {
    final statusCounts = <String, int>{};
    
    for (final agent in _agents.values) {
      final status = agent.status.name;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    
    return {
      'total_agents': _agents.length,
      'status_counts': statusCounts,
      'categories': _agentsByCategory.keys.toList(),
      'agents': _agents.values.map((a) => a.getInfo()).toList(),
    };
  }

  /// Emit an event
  void _emitEvent(String agentId, AgentEvent event, {Map<String, dynamic>? metadata}) {
    _eventController.add(AgentEventData(
      agentId: agentId,
      event: event,
      metadata: metadata,
    ));
  }

  /// Dispose the registry
  void dispose() {
    _eventController.close();
    for (final agent in _agents.values) {
      agent.dispose();
    }
    _agents.clear();
    _agentsByCategory.clear();
  }
}
