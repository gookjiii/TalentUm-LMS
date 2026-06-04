import 'dart:math';
import 'dart:typed_data';
import 'package:diffutil_dart/diffutil.dart' as diffutil;
import 'package:flutter_chat_core/flutter_chat_core.dart';

final class _Diagonal {
  final int x;
  final int y;
  final int size;

  _Diagonal(this.x, this.y, this.size);

  int endX() => x + size;
  int endY() => y + size;
}

int _diagonalComparator(_Diagonal o1, _Diagonal o2) {
  return o1.x - o2.x;
}

final class _Range {
  int oldListStart;
  int oldListEnd;
  int newListStart;
  int newListEnd;

  _Range({
    required this.oldListStart,
    required this.oldListEnd,
    required this.newListStart,
    required this.newListEnd,
  });

  _Range.empty()
      : oldListStart = 0,
        oldListEnd = 0,
        newListStart = 0,
        newListEnd = 0;

  int oldSize() => oldListEnd - oldListStart;
  int newSize() => newListEnd - newListStart;
}

final class _CenteredArray {
  final Int32List data;
  final int _mid;

  _CenteredArray(int size)
      : _mid = size ~/ 2,
        data = Int32List(size);

  int operator [](int index) => data[_mid + index];
  void operator []=(int index, int value) => data[_mid + index] = value;

  void fill(int value) => data.fillRange(0, data.length, value);
}

final class _Snake {
  final int startX;
  final int startY;
  final int endX;
  final int endY;
  final bool reverse;

  _Snake({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.reverse,
  });

  bool hasAdditionOrRemoval() => endY - startY != endX - startX;
  bool isAddition() => endY - startY > endX - startX;
  int diagonalSize() => min(endX - startX, endY - startY);

  _Diagonal toDiagonal() {
    if (hasAdditionOrRemoval()) {
      if (reverse) {
        return _Diagonal(startX, startY, diagonalSize());
      } else {
        if (isAddition()) {
          return _Diagonal(startX, startY + 1, diagonalSize());
        } else {
          return _Diagonal(startX + 1, startY, diagonalSize());
        }
      }
    } else {
      return _Diagonal(startX, startY, endX - startX);
    }
  }
}

class _PostponedUpdate {
  final int posInOwnerList;
  int currentPos;
  final bool removal;

  _PostponedUpdate({
    required this.posInOwnerList,
    required this.currentPos,
    required this.removal,
  });
}

class MessageDiffResult {
  static const int FLAG_NOT_CHANGED = 1;
  static const int FLAG_CHANGED = FLAG_NOT_CHANGED << 1;
  static const int FLAG_MOVED_CHANGED = FLAG_CHANGED << 1;
  static const int FLAG_MOVED_NOT_CHANGED = FLAG_MOVED_CHANGED << 1;
  static const int FLAG_MOVED = FLAG_MOVED_CHANGED | FLAG_MOVED_NOT_CHANGED;
  static const int FLAG_OFFSET = 4;
  static const int FLAG_MASK = (1 << FLAG_OFFSET) - 1;

  final List<Message> oldList;
  final List<Message> newList;
  final List<_Diagonal> _mDiagonals;
  final List<int> _mOldItemStatuses;
  final List<int> _mNewItemStatuses;
  final bool _mDetectMoves;

  MessageDiffResult({
    required this.oldList,
    required this.newList,
    required List<_Diagonal> diagonals,
    required List<int> oldItemStatuses,
    required List<int> newItemStatuses,
    required bool detectMoves,
  })  : _mDiagonals = diagonals,
        _mOldItemStatuses = oldItemStatuses,
        _mNewItemStatuses = newItemStatuses,
        _mDetectMoves = detectMoves {
    if (_mOldItemStatuses.isNotEmpty) {
      _mOldItemStatuses.fillRange(0, _mOldItemStatuses.length - 1, 0);
    }
    if (_mNewItemStatuses.isNotEmpty) {
      _mNewItemStatuses.fillRange(0, _mNewItemStatuses.length - 1, 0);
    }
    _addEdgeDiagonals();
    _findMatchingItems();
  }

  void _addEdgeDiagonals() {
    final first = _mDiagonals.isEmpty ? null : _mDiagonals[0];
    if (first == null || first.x != 0 || first.y != 0) {
      _mDiagonals.insert(0, _Diagonal(0, 0, 0));
    }
    _mDiagonals.add(_Diagonal(oldList.length, newList.length, 0));
  }

  void _findMatchingItems() {
    for (_Diagonal diagonal in _mDiagonals) {
      for (int offset = 0; offset < diagonal.size; offset++) {
        final int posX = diagonal.x + offset;
        final int posY = diagonal.y + offset;
        final bool theSame = oldList[posX] == newList[posY];
        final int changeFlag = theSame ? FLAG_NOT_CHANGED : FLAG_CHANGED;
        _mOldItemStatuses[posX] = (posY << FLAG_OFFSET) | changeFlag;
        _mNewItemStatuses[posY] = (posX << FLAG_OFFSET) | changeFlag;
      }
    }
    if (_mDetectMoves) {
      _findMoveMatches();
    }
  }

  void _findMoveMatches() {
    int posX = 0;
    for (_Diagonal diagonal in _mDiagonals) {
      while (posX < diagonal.x) {
        if (_mOldItemStatuses[posX] == 0) {
          _findMatchingAddition(posX);
        }
        posX++;
      }
      posX = diagonal.endX();
    }
  }

  void _findMatchingAddition(int posX) {
    int posY = 0;
    final int diagonalsSize = _mDiagonals.length;
    for (int i = 0; i < diagonalsSize; i++) {
      final _Diagonal diagonal = _mDiagonals[i];
      while (posY < diagonal.y) {
        if (_mNewItemStatuses[posY] == 0) {
          final matching = oldList[posX].id == newList[posY].id;
          if (matching) {
            final contentsMatching = oldList[posX] == newList[posY];
            final int changeFlag =
                contentsMatching ? FLAG_MOVED_NOT_CHANGED : FLAG_MOVED_CHANGED;
            _mOldItemStatuses[posX] = (posY << FLAG_OFFSET) | changeFlag;
            _mNewItemStatuses[posY] = (posX << FLAG_OFFSET) | changeFlag;
            return;
          }
        }
        posY++;
      }
      posY = diagonal.endY();
    }
  }

  List<diffutil.DataDiffUpdate<Message>> getUpdatesWithData() {
    final updates = <diffutil.DataDiffUpdate<Message>>[];
    int currentListSize = oldList.length;
    final postponedUpdates = <_PostponedUpdate>[];
    int posX = oldList.length;
    int posY = newList.length;

    for (int diagonalIndex = _mDiagonals.length - 1;
        diagonalIndex >= 0;
        diagonalIndex--) {
      final _Diagonal diagonal = _mDiagonals[diagonalIndex];
      final int endX = diagonal.endX();
      final int endY = diagonal.endY();

      while (posX > endX) {
        posX--;
        final int status = _mOldItemStatuses[posX];
        final item = oldList[posX];
        if ((status & FLAG_MOVED) != 0) {
          final int newPos = status >> FLAG_OFFSET;
          final _PostponedUpdate? postponedUpdate =
              _getPostponedUpdate(postponedUpdates, newPos, false);
          if (postponedUpdate != null) {
            final int updatedNewPos =
                currentListSize - postponedUpdate.currentPos;
            updates.add(diffutil.DataMove<Message>(
                from: posX, to: updatedNewPos - 1, data: item));
            if ((status & FLAG_MOVED_CHANGED) != 0) {
              updates.add(diffutil.DataChange<Message>(
                position: updatedNewPos - 1,
                oldData: item,
                newData: newList[newPos],
              ));
            }
          } else {
            postponedUpdates.add(_PostponedUpdate(
                posInOwnerList: posX,
                currentPos: currentListSize - posX - 1,
                removal: true));
          }
        } else {
          updates.add(diffutil.DataRemove<Message>(position: posX, data: item));
          currentListSize--;
        }
      }

      while (posY > endY) {
        posY--;
        final int status = _mNewItemStatuses[posY];
        final item = newList[posY];

        if ((status & FLAG_MOVED) != 0) {
          final int oldPos = status >> FLAG_OFFSET;
          final _PostponedUpdate? postponedUpdate =
              _getPostponedUpdate(postponedUpdates, oldPos, true);
          if (postponedUpdate == null) {
            postponedUpdates.add(_PostponedUpdate(
                posInOwnerList: posY,
                currentPos: currentListSize - posX,
                removal: false));
          } else {
            final int updatedOldPos =
                currentListSize - postponedUpdate.currentPos - 1;
            updates.add(diffutil.DataMove<Message>(
                from: updatedOldPos, to: posX, data: item));
            if ((status & FLAG_MOVED_CHANGED) != 0) {
              updates.add(diffutil.DataDiffUpdate.change(
                  position: posX, oldData: oldList[oldPos], newData: item));
            }
          }
        } else {
          updates.add(diffutil.DataInsert<Message>(position: posX, data: item));
          currentListSize++;
        }
      }

      posX = diagonal.x;
      posY = diagonal.y;
      for (int i = 0; i < diagonal.size; i++) {
        if ((_mOldItemStatuses[posX] & FLAG_MASK) == FLAG_CHANGED) {
          updates.add(diffutil.DataDiffUpdate.change(
              position: posX, oldData: oldList[posX], newData: newList[posY]));
        }
        posX++;
        posY++;
      }

      posX = diagonal.x;
      posY = diagonal.y;
    }
    return updates;
  }

  _PostponedUpdate? _getPostponedUpdate(
      List<_PostponedUpdate> postponedUpdates, int posInList, bool removal) {
    _PostponedUpdate? postponedUpdate;
    int i = 0;
    while (i < postponedUpdates.length) {
      final update = postponedUpdates.elementAt(i);
      if (update.posInOwnerList == posInList && update.removal == removal) {
        postponedUpdate = update;
        postponedUpdates.removeAt(i);
        break;
      }
      i++;
    }
    while (i < postponedUpdates.length) {
      final update = postponedUpdates.elementAt(i);
      if (removal) {
        update.currentPos--;
      } else {
        update.currentPos++;
      }
      i++;
    }
    return postponedUpdate;
  }
}

List<diffutil.DataDiffUpdate<Message>> calculateMessageDiff(
  List<Message> oldList,
  List<Message> newList, {
  bool detectMoves = true,
}) {
  final oldSize = oldList.length;
  final newSize = newList.length;
  final diagonals = <_Diagonal>[];
  final stack = <_Range>[];
  stack.add(_Range(
      oldListStart: 0,
      oldListEnd: oldSize,
      newListStart: 0,
      newListEnd: newSize));
  final maxVal = (oldSize + newSize + 1) ~/ 2;
  final forward = _CenteredArray(maxVal * 2 + 1);
  final backward = _CenteredArray(maxVal * 2 + 1);
  final rangePool = <_Range>[];

  while (stack.isNotEmpty) {
    final range = stack.removeLast();
    final snake = _midPoint(range, oldList, newList, forward, backward);

    if (snake != null) {
      if (snake.diagonalSize() > 0) {
        diagonals.add(snake.toDiagonal());
      }

      final _Range left = rangePool.isEmpty
          ? _Range.empty()
          : rangePool.removeAt(rangePool.length - 1);
      left.oldListStart = range.oldListStart;
      left.newListStart = range.newListStart;
      left.oldListEnd = snake.startX;
      left.newListEnd = snake.startY;

      stack.add(left);

      final _Range right = range;
      right.oldListEnd = range.oldListEnd;
      right.newListEnd = range.newListEnd;
      right.oldListStart = snake.endX;
      right.newListStart = snake.endY;
      stack.add(right);
    } else {
      rangePool.add(range);
    }
  }
  diagonals.sort(_diagonalComparator);

  final result = MessageDiffResult(
    oldList: oldList,
    newList: newList,
    diagonals: diagonals,
    oldItemStatuses: forward.data,
    newItemStatuses: backward.data,
    detectMoves: detectMoves,
  );

  return result.getUpdatesWithData();
}

_Snake? _midPoint(
  _Range range,
  List<Message> oldList,
  List<Message> newList,
  _CenteredArray forward,
  _CenteredArray backward,
) {
  if (range.oldSize() < 1 || range.newSize() < 1) {
    return null;
  }
  final maxVal = (range.oldSize() + range.newSize() + 1) ~/ 2;
  forward[1] = range.oldListStart;
  backward[1] = range.oldListEnd;
  for (int d = 0; d < maxVal; d++) {
    _Snake? snake = _forwardSnake(range, oldList, newList, forward, backward, d);
    if (snake != null) {
      return snake;
    }
    snake = _backwardSnake(range, oldList, newList, forward, backward, d);
    if (snake != null) {
      return snake;
    }
  }
  return null;
}

_Snake? _forwardSnake(
  _Range range,
  List<Message> oldList,
  List<Message> newList,
  _CenteredArray forward,
  _CenteredArray backward,
  int d,
) {
  final bool checkForSnake = (range.oldSize() - range.newSize()).abs() % 2 == 1;
  final delta = range.oldSize() - range.newSize();
  for (int k = -d; k <= d; k += 2) {
    final int startX;
    final int startY;
    int x, y;
    if (k == -d || (k != d && forward[k + 1] > forward[k - 1])) {
      x = startX = forward[k + 1];
    } else {
      startX = forward[k - 1];
      x = startX + 1;
    }
    y = range.newListStart + (x - range.oldListStart) - k;
    startY = (d == 0 || x != startX) ? y : y - 1;
    while (x < range.oldListEnd &&
        y < range.newListEnd &&
        oldList[x].id == newList[y].id) {
      x++;
      y++;
    }
    forward[k] = x;
    if (checkForSnake) {
      final backwardsK = delta - k;
      if (backwardsK >= -d + 1 &&
          backwardsK <= d - 1 &&
          backward[backwardsK] <= x) {
        final snake = _Snake(
            startX: startX, startY: startY, endX: x, endY: y, reverse: false);
        return snake;
      }
    }
  }
  return null;
}

_Snake? _backwardSnake(
  _Range range,
  List<Message> oldList,
  List<Message> newList,
  _CenteredArray forward,
  _CenteredArray backward,
  int d,
) {
  final checkForSnake = (range.oldSize() - range.newSize()) % 2 == 0;
  final delta = range.oldSize() - range.newSize();
  for (int k = -d; k <= d; k += 2) {
    final int startX;
    final int startY;
    int x, y;

    if (k == -d || (k != d && backward[k + 1] < backward[k - 1])) {
      x = startX = backward[k + 1];
    } else {
      startX = backward[k - 1];
      x = startX - 1;
    }
    y = range.newListEnd - ((range.oldListEnd - x) - k);
    startY = (d == 0 || x != startX) ? y : y + 1;
    while (x > range.oldListStart &&
        y > range.newListStart &&
        oldList[x - 1].id == newList[y - 1].id) {
      x--;
      y--;
    }
    backward[k] = x;
    if (checkForSnake) {
      final forwardsK = delta - k;
      if (forwardsK >= -d && forwardsK <= d && forward[forwardsK] >= x) {
        final snake = _Snake(
            startX: x, startY: y, endX: startX, endY: startY, reverse: true);
        return snake;
      }
    }
  }
  return null;
}
