/// トラックログの保存間隔を管理する列挙型
/// intervalSeconds: GPS ポイントを記録する間隔（秒）
enum TrackIntervalType {
  sec5('5秒', 5),
  sec10('10秒', 10),
  sec30('30秒', 30),
  min1('1分', 60),
  min3('3分', 180),
  min5('5分', 300);

  final String label;
  final int intervalSeconds;
  const TrackIntervalType(this.label, this.intervalSeconds);
}

/// トラックログの表示期間を管理する列挙型
/// days: 何日前までのログを地図上に表示するか（0 = 無制限）
enum TrackDisplayDaysType {
  unlimited('無制限', 0),
  day1('1日', 1),
  day3('3日', 3),
  week1('1週間', 7),
  month1('1ヶ月', 30),
  month3('3ヶ月', 90);

  final String label;
  final int days;
  const TrackDisplayDaysType(this.label, this.days);
}

/*
 * 機能: 保存期間（日数）を選択し、その日数より古いトラックログを自動削除する。
 * 状態: ユーザーが一覧から明示的に削除する運用へ変更したため停止中。
 * 再導入する場合は SettingStorageData、設定画面、TrackLocalDataSource も併せて有効化する。
enum TrackRetentionDaysType {
  unlimited('無制限', 0),
  week1('1週間', 7),
  month1('1ヶ月', 30),
  month3('3ヶ月', 90),
  month6('6ヶ月', 180),
  year1('1年', 365);

  final String label;
  final int days;
  const TrackRetentionDaysType(this.label, this.days);
}
*/
