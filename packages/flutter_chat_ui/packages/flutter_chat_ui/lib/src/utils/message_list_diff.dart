import 'package:diffutil_dart/diffutil.dart' as diffutil;
import 'package:flutter_chat_core/flutter_chat_core.dart';

/// A [diffutil.ListDiffDelegate] implementation for comparing lists of [Message] objects.
///
/// Used by `diffutil_dart` to calculate differences between old and new message lists
/// for efficient updates in animated lists.
class MessageListDiff implements diffutil.IndexableItemDiffDelegate<Message> {
  /// The old list of messages.
  final List<Message> oldList;

  /// The new list of messages.
  final List<Message> newList;

  /// Creates a diff delegate for comparing two message lists.
  MessageListDiff(this.oldList, this.newList);

  @override
  int getOldListSize() => oldList.length;

  @override
  int getNewListSize() => newList.length;

  @override
  Message getOldItemAtIndex(int index) => oldList[index];

  @override
  Message getNewItemAtIndex(int index) => newList[index];

  /// Checks if the content of two messages at the given positions is the same.
  /// Uses [equalityChecker] from `freezed_annotation` for deep comparison.
  @override
  bool areContentsTheSame(int oldItemPosition, int newItemPosition) =>
      oldList[oldItemPosition] == newList[newItemPosition];

  /// Checks if two messages at the given positions represent the same item.
  /// Compares messages based on their unique [id].
  @override
  bool areItemsTheSame(int oldItemPosition, int newItemPosition) =>
      oldList[oldItemPosition].id == newList[newItemPosition].id;

  @override
  Object? getChangePayload(int oldItemPosition, int newItemPosition) => null;
}
