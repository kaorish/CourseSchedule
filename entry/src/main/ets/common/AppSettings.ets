// 定义AppStorage中使用的键，方便统一管理和引用

export class AppSettings {
  public static readonly ADVANCE_MINUTES_KEY = 'settings_advance_minutes';
  public static readonly CURRENT_SEMESTER_ID_KEY = 'current_semester_id';
  public static readonly CURRENT_SEMESTER_START_DATE_KEY = 'current_semester_start_date';
  public static readonly CURRENT_SEMESTER_TOTAL_WEEKS_KEY = 'current_semester_total_weeks';

  public static initialize(): void {
    // ★★★ 核心修改：如果AppStorage中没有存储过学期ID，则将初始值设为 1 ★★★
    if (AppStorage.Get(AppSettings.CURRENT_SEMESTER_ID_KEY) === undefined) {
      AppStorage.Set(AppSettings.CURRENT_SEMESTER_ID_KEY, 1);
    }
    if (AppStorage.Get(AppSettings.ADVANCE_MINUTES_KEY) === undefined) {
      AppStorage.Set(AppSettings.ADVANCE_MINUTES_KEY, 5);
    }
  }
}