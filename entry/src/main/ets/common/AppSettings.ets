// 文件路径: entry/src/main/ets/common/AppSettings.ets

export class AppSettings {
  public static readonly CURRENT_SEMESTER_ID_KEY = 'current_semester_id';
  public static readonly CURRENT_SEMESTER_START_DATE_KEY = 'current_semester_start_date';
  public static readonly CURRENT_SEMESTER_TOTAL_WEEKS_KEY = 'current_semester_total_weeks';
  public static readonly ADVANCE_MINUTES_KEY = 'advance_minutes';

  // --- 新增：用于存储用户手动设置的周数 ---
  // -1 表示用户没有设置过，应采用自动计算
  public static readonly USER_OVERRIDDEN_WEEK_KEY = 'user_overridden_week';


  public static initialize(): void {
    if (AppStorage.Get(AppSettings.CURRENT_SEMESTER_ID_KEY) === undefined) {
      AppStorage.Set(AppSettings.CURRENT_SEMESTER_ID_KEY, 1);
    }
    if (AppStorage.Get(AppSettings.ADVANCE_MINUTES_KEY) === undefined) {
      AppStorage.Set(AppSettings.ADVANCE_MINUTES_KEY, 5);
    }
    // --- 新增：初始化用户自定义周数 ---
    if (AppStorage.Get(AppSettings.USER_OVERRIDDEN_WEEK_KEY) === undefined) {
      AppStorage.Set(AppSettings.USER_OVERRIDDEN_WEEK_KEY, -1);
    }
  }
}