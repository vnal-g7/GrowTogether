class AppLevels {
  static int levelFromXp(int xp) {
    if (xp < 50) return 1;
    if (xp < 120) return 2;
    if (xp < 220) return 3;
    if (xp < 360) return 4;
    if (xp < 550) return 5;
    if (xp < 800) return 6;
    if (xp < 1100) return 7;
    if (xp < 1450) return 8;
    if (xp < 1850) return 9;
    return 10;
  }

  static String rankTitleFromXp(int xp) {
    final level = levelFromXp(xp);

    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Attendee';
      case 3:
        return 'Committed';
      case 4:
        return 'Consistent';
      case 5:
        return 'Riser';
      case 6:
        return 'Focused';
      case 7:
        return 'Dedicated';
      case 8:
        return 'Elite';
      case 9:
        return 'Champion';
      default:
        return 'Legend';
    }
  }

  static int xpForNextLevel(int xp) {
    final level = levelFromXp(xp);

    switch (level) {
      case 1:
        return 50;
      case 2:
        return 120;
      case 3:
        return 220;
      case 4:
        return 360;
      case 5:
        return 550;
      case 6:
        return 800;
      case 7:
        return 1100;
      case 8:
        return 1450;
      case 9:
        return 1850;
      default:
        return 1850;
    }
  }

  static double progressToNextLevel(int xp) {
    final level = levelFromXp(xp);

    final levelStart = _levelStartXp(level);
    final next = xpForNextLevel(xp);

    if (next <= levelStart) return 1;

    final progress = (xp - levelStart) / (next - levelStart);
    return progress.clamp(0, 1).toDouble();
  }

  static int _levelStartXp(int level) {
    switch (level) {
      case 1:
        return 0;
      case 2:
        return 50;
      case 3:
        return 120;
      case 4:
        return 220;
      case 5:
        return 360;
      case 6:
        return 550;
      case 7:
        return 800;
      case 8:
        return 1100;
      case 9:
        return 1450;
      default:
        return 1850;
    }
  }
}