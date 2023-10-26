import 'dart:collection';
import 'dart:math';

class CellEntry<T> {
  final T obj;
  final double x;
  final double y;

  const CellEntry(this.x, this.y, this.obj);
}

class GridKey {
  final int row;
  final int col;

  const GridKey(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is GridKey && other.row == row && other.col == col;

  @override
  int get hashCode => (col << 26) ^ row;
}

class DistanceGrid<T> {
  final int cellSize;
  final double _sqCellSize;

  final _grid = HashMap<GridKey, List<CellEntry<T>>>();
  final _objectPoint = HashMap<T, GridKey>();

  DistanceGrid(int cellSize)
      : cellSize = cellSize > 0 ? cellSize : 1,
        _sqCellSize = (cellSize * cellSize).toDouble();

  void clear() {
    _grid.clear();
    _objectPoint.clear();
  }

  void addObject(T obj, Point<double> point) {
    final key = GridKey(_getCoord(point.y), _getCoord(point.x));
    final cell = _grid[key] ??= [];

    _objectPoint[obj] = key;
    cell.add(CellEntry<T>(point.x, point.y, obj));
  }

  void updateObject(T obj, Point<double> point) {
    removeObject(obj);
    addObject(obj, point);
  }

  //Returns true if the object was found
  bool removeObject(T obj) {
    final key = _objectPoint.remove(obj);
    if (key == null) return false;

    // Object existed in the _objectPoint map, thus must exist in the grid.
    final cell = _grid[key]!;
    cell.removeWhere((e) => e.obj == obj);
    if (cell.isEmpty) {
      _grid.remove(key);
    }
    return true;
  }

  void eachObject(Function(T) fn) {
    for (final cell in _grid.values) {
      for (final entry in cell) {
        fn(entry.obj);
      }
    }
  }

  T? getNearObject(Point<double> point) {
    final px = point.x;
    final py = point.y;

    final x = _getCoord(px), y = _getCoord(py);
    double closestDistSq = _sqCellSize;
    T? closest;

    // Checks rows and columns with index +/- 1.
    for (int i = y - 1; i <= y + 1; i++) {
      for (int j = x - 1; j <= x + 1; j++) {
        final cell = _grid[GridKey(i, j)];
        if (cell != null) {
          for (final entry in cell) {
            final double dx = px - entry.x;
            final double dy = py - entry.y;
            final double distSq = dx * dx + dy * dy;

            if (distSq <= closestDistSq) {
              closestDistSq = distSq;
              closest = entry.obj;
            }
          }
        }
      }
    }

    return closest;
  }

  int _getCoord(double x) => x ~/ cellSize;
}
