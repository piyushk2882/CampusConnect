import 'package:insta_blocks/insta_blocks.dart';
import 'package:json_annotation/json_annotation.dart';

/// {@template block_action_converter}
/// A [JsonConverter] that supports (de)serializing a [BlockAction].
/// {@endtemplate}
class BlockActionConverter
    implements JsonConverter<BlockAction?, Map<String, dynamic>?> {
  /// {@macro block_action_converter}
  const BlockActionConverter();

  @override
  BlockAction? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return BlockAction.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(BlockAction? object) {
    if (object == null) return null;
    return object.toJson();
  }
}
