/// Layout tokens shared by every screen.
class Spacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Side padding that grows a little on wide phones and tablets.
  static double pageGutter(double width) => width >= 600 ? 32 : 20;
}

class Radii {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const pill = 999.0;
}

class IconSizes {
  static const sm = 18.0;
  static const md = 22.0;
  static const lg = 28.0;
}

class Heights {
  static const button = 52.0;
  static const input = 52.0;
  static const minTouch = 48.0;
}
