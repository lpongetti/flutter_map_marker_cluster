import 'dart:math';

class DistanceGrid<T> {
  final num cellSize;

  final num _sqCellSize;
  final Map<num, Map<num, List<T>>> _grid = {};
  final Map<T, Point> _objectPoint = {};

  DistanceGrid(this.cellSize) : _sqCellSize = cellSize * cellSize;

  void addObject(T obj, Point point) {
    final x = _getCoord(point.x), y = _getCoord(point.y);
    final row = _grid[y] ??= {};
    final cell = row[x] ??= [];

    _objectPoint[obj] = point;

    cell.add(obj);
  }

  void updateObject(T obj, Point point) {
    removeObject(obj);
    addObject(obj, point);
  }

  //Returns true if the object was found
  bool removeObject(T obj) {
    final point = _objectPoint[obj];
    if (point == null) return false;

    final x = _getCoord(point.x), y = _getCoord(point.y);
    final row = _grid[y] ??= {};
    final cell = row[x] ??= [];

    _objectPoint.remove(obj);

    final len = cell.length;
    for (var i = 0; i < len; i++) {
      if (cell[i] == obj) {
        cell.removeAt(i);

        if (len == 1) {
          row.remove(x);

          if (_grid[y]!.isEmpty) {
            _grid.remove(y);
          }
        }

        return true;
      }
    }
    return false;
  }

  void eachObject(Function(T) fn) {
    for (final i in _grid.keys) {
      final row = _grid[i]!;

      for (final j in row.keys) {
        final cell = row[j]!;

        for (var k = 0; k < cell.length; k++) {
          fn(cell[k]);
        }
      }
    }
  }

  T? getNearObject(Point point) {
    final x = _getCoord(point.x), y = _getCoord(point.y);
    var closestDistSq = _sqCellSize;
    T? closest;

    for (var i = y - 1; i <= y + 1; i++) {
      final row = _grid[i];
      if (row != null) {
        for (var j = x - 1; j <= x + 1; j++) {
          final cell = row[j];
          if (cell != null) {
            for (var k = 0; k < cell.length; k++) {
              final obj = cell[k];
              final dist = _sqDist(_objectPoint[obj]!, point);

              if (dist < closestDistSq ||
                  dist <= closestDistSq && closest == null) {
                closestDistSq = dist;
                closest = obj;
              }
            }
          }
        }
      }
    }
    return closest;
  }

  num _getCoord(num x) {
    final coord = x / cellSize;
    return coord.isFinite ? coord.floor() : x;
  }

  num _sqDist(Point p1, Point p2) {
    final dx = p2.x - p1.x, dy = p2.y - p1.y;
    return dx * dx + dy * dy;
  }
}
