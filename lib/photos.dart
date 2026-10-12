/// Bundled photography (assets/images/photos), chosen to match each use.
class Photos {
  static const _dir = 'assets/images/photos';

  /// Gold herringbone chain against black — dark, quiet: the welcome film and
  /// the Solid Gold finish.
  static const chainNoir = '$_dir/chain-noir.jpg';

  /// Fine necklace worn at the open collar.
  static const wornCollar = '$_dir/worn-collar.jpg';

  /// Hand resting on a layered necklace, warm side light.
  static const wornLight = '$_dir/worn-light.jpg';

  /// Gold pendant necklace — Model 01 (pendant that becomes glasses).
  static const model01 = '$_dir/model01-pendant.jpg';

  /// Hands lifting the necklace — Model 02 (lifts into a handheld lens).
  static const model02 = '$_dir/model02-lift.jpg';

  /// Necklace back in place after use.
  static const wornReturn = '$_dir/worn-return.jpg';

  static const welcomeFilm = [chainNoir, wornCollar, wornLight];
  static const finishSolidGold = chainNoir;
  static const finishGoldPlated = wornCollar;

  static const all = [chainNoir, wornCollar, wornLight, model01, model02, wornReturn];
}
