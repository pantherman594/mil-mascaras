enum Direction {
  forward,
  backward,
  left,
  right,
  stop,
}

extension DirectionCommand on Direction {
  String get start {
    switch(this) {
      case Direction.forward:
        return "forward";
      case Direction.backward:
        return "backward";
      case Direction.left:
        return "left";
      case Direction.right:
        return "right";
      case Direction.stop:
        return "stop";
    }
  }

  String get stop {
    switch(this) {
      case Direction.stop:
        return "stop";
      default:
        return start + "_up";
    }
  }
}
