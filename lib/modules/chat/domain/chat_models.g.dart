// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatResponse _$ChatResponseFromJson(Map<String, dynamic> json) => ChatResponse(
      status: json['status'] as String,
      conversationId: json['conversation_id'] as String?,
      messageId: json['message_id'] as String?,
      answer: Answer.fromJson(json['answer'] as Map<String, dynamic>),
      mode: json['mode'] as String?,
      toolUsed: json['tool_used'] as String?,
    );

Map<String, dynamic> _$ChatResponseToJson(ChatResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'conversation_id': instance.conversationId,
      'message_id': instance.messageId,
      'answer': instance.answer,
      'mode': instance.mode,
      'tool_used': instance.toolUsed,
    };

Answer _$AnswerFromJson(Map<String, dynamic> json) => Answer(
      status: json['status'] as String,
      summary: json['summary'] as String?,
      blocks: (json['blocks'] as List<dynamic>)
          .map((e) => Block.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnswerToJson(Answer instance) => <String, dynamic>{
      'status': instance.status,
      'summary': instance.summary,
      'blocks': instance.blocks,
    };

Block _$BlockFromJson(Map<String, dynamic> json) => Block(
      type: json['type'] as String,
      content: json['content'] as String?,
      metrics: (json['metrics'] as List<dynamic>?)
          ?.map((e) => MetricItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      title: json['title'] as String?,
      description: json['description'] as String?,
      headers:
          (json['headers'] as List<dynamic>?)?.map((e) => e as String).toList(),
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => e as List<dynamic>)
          .toList(),
      totalRows: (json['total_rows'] as num?)?.toInt(),
      chartType: json['chart_type'] as String?,
      xKey: json['x_key'] as String?,
      yKeys:
          (json['y_keys'] as List<dynamic>?)?.map((e) => e as String).toList(),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      items:
          (json['items'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$BlockToJson(Block instance) => <String, dynamic>{
      'type': instance.type,
      'content': instance.content,
      'metrics': instance.metrics,
      'title': instance.title,
      'description': instance.description,
      'headers': instance.headers,
      'rows': instance.rows,
      'total_rows': instance.totalRows,
      'chart_type': instance.chartType,
      'x_key': instance.xKey,
      'y_keys': instance.yKeys,
      'data': instance.data,
      'items': instance.items,
    };

MetricItem _$MetricItemFromJson(Map<String, dynamic> json) => MetricItem(
      label: json['label'] as String,
      value: json['value'] as String,
      rawValue: json['raw_value'],
    );

Map<String, dynamic> _$MetricItemToJson(MetricItem instance) =>
    <String, dynamic>{
      'label': instance.label,
      'value': instance.value,
      'raw_value': instance.rawValue,
    };
