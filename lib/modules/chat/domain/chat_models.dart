
import 'package:json_annotation/json_annotation.dart';

part 'chat_models.g.dart';

@JsonSerializable()
class ChatResponse {
  final String status;
  @JsonKey(name: 'conversation_id')
  final String? conversationId;
  @JsonKey(name: 'message_id')
  final String? messageId;
  final Answer answer;
  final String? mode;
  @JsonKey(name: 'tool_used')
  final String? toolUsed;

  ChatResponse({
    required this.status,
    this.conversationId,
    this.messageId,
    required this.answer,
    this.mode,
    this.toolUsed,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) => _$ChatResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatResponseToJson(this);
}

@JsonSerializable()
class Answer {
  final String status;
  final String? summary;
  final List<Block> blocks;

  Answer({required this.status, this.summary, required this.blocks});

  factory Answer.fromJson(Map<String, dynamic> json) => _$AnswerFromJson(json);
  Map<String, dynamic> toJson() => _$AnswerToJson(this);
}

@JsonSerializable()
class Block {
  final String type;
  final String? content; // For text
  final List<MetricItem>? metrics; // For metrics
  final String? title; // For table/chart
  final String? description; // For table
  final List<String>? headers; // For table
  final List<List<dynamic>>? rows; // For table
  @JsonKey(name: 'total_rows')
  final int? totalRows; // For table
  @JsonKey(name: 'chart_type')
  final String? chartType; // For chart
  @JsonKey(name: 'x_key')
  final String? xKey; // For chart
  @JsonKey(name: 'y_keys')
  final List<String>? yKeys; // For chart
  final List<Map<String, dynamic>>? data; // For chart
  final List<String>? items; // For suggestions

  Block({
    required this.type,
    this.content,
    this.metrics,
    this.title,
    this.description,
    this.headers,
    this.rows,
    this.totalRows,
    this.chartType,
    this.xKey,
    this.yKeys,
    this.data,
    this.items,
  });

  factory Block.fromJson(Map<String, dynamic> json) => _$BlockFromJson(json);
  Map<String, dynamic> toJson() => _$BlockToJson(this);
}

@JsonSerializable()
class MetricItem {
  final String label;
  final String value;
  @JsonKey(name: 'raw_value')
  final dynamic rawValue;

  MetricItem({required this.label, required this.value, this.rawValue});

  factory MetricItem.fromJson(Map<String, dynamic> json) => _$MetricItemFromJson(json);
  Map<String, dynamic> toJson() => _$MetricItemToJson(this);
}
