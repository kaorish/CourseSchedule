// 文件路径: entry/src/main/ets/common/AppSettings.ets

export class AppSettings {
  public static readonly CURRENT_SEMESTER_ID_KEY = 'current_semester_id';
  public static readonly CURRENT_SEMESTER_START_DATE_KEY = 'current_semester_start_date';
  public static readonly CURRENT_SEMESTER_TOTAL_WEEKS_KEY = 'current_semester_total_weeks';
  public static readonly ADVANCE_MINUTES_KEY = 'advance_minutes';
  public static readonly USER_OVERRIDDEN_WEEK_KEY = 'user_overridden_week';

  // --- 新增：用于存储自动计算的当前周数 ---
  public static readonly CALCULATED_CURRENT_WEEK_KEY = 'calculated_current_week';


  public static initialize(): void {
    if (AppStorage.Get(AppSettings.CURRENT_SEMESTER_ID_KEY) === undefined) {
      AppStorage.Set(AppSettings.CURRENT_SEMESTER_ID_KEY, 1);
    }
    if (AppStorage.Get(AppSettings.ADVANCE_MINUTES_KEY) === undefined) {
      AppStorage.Set(AppSettings.ADVANCE_MINUTES_KEY, 5);
    }
    if (AppStorage.Get(AppSettings.USER_OVERRIDDEN_WEEK_KEY) === undefined) {
      AppStorage.Set(AppSettings.USER_OVERRIDDEN_WEEK_KEY, -1);
    }
    // --- 新增：初始化计算周数 ---
    if (AppStorage.Get(AppSettings.CALCULATED_CURRENT_WEEK_KEY) === undefined) {
      AppStorage.Set(AppSettings.CALCULATED_CURRENT_WEEK_KEY, 1);
    }
  }
}