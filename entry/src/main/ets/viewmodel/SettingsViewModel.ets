// 文件路径: entry/src/main/ets/viewmodel/SettingsViewModel.ets

import { httpUtil } from '../utils/HttpUtil';
import { Semester } from '../model/Semester';
import { SemesterUpdateDTO } from '../model/SemesterUpdateDTO';
import promptAction from '@ohos.promptAction';
import { AppSettings } from '../common/AppSettings';

@Observed
export class SettingsViewModel {
  semesters: Semester[] = [];
  isLoading: boolean = false;
  errorMessage: string = '';

  // --- 1. 修正：将 currentWeekNumber 属性加回来 ---
  currentWeekNumber: number = 1;

  constructor() {
    // ViewModel一创建，就立即尝试计算一次当前周数
    this.calculateCurrentWeek();
  }

  // --- 2. 新增：计算当前周数的业务逻辑 ---
  public calculateCurrentWeek(): void {
    // 从AppStorage中获取本学期的开始日期
    const startDateStr = AppStorage.Get<string>(AppSettings.CURRENT_SEMESTER_START_DATE_KEY);

    // 如果没有有效的开始日期，则默认为第1周
    if (!startDateStr || typeof startDateStr !== 'string') {
      console.log("[calculateCurrentWeek] No valid start date found in AppStorage.");
      this.currentWeekNumber = 1;
      return;
    }

    try {
      const startDate = new Date(startDateStr);
      const today = new Date();

      // 忽略时间，只比较日期，防止跨时区问题
      startDate.setHours(0, 0, 0, 0);
      today.setHours(0, 0, 0, 0);

      // 如果今天还没到开学日期，则算作第1周
      if (today < startDate) {
        this.currentWeekNumber = 1;
        return;
      }

      const millisecondsPerDay = 1000 * 60 * 60 * 24;
      // 计算两个日期之间相差的毫秒数
      const diffMilliseconds = today.getTime() - startDate.getTime();
      // 计算相差的天数
      const daysDifference = Math.floor(diffMilliseconds / millisecondsPerDay);
      // 根据天数计算周数（第0-6天为第1周）
      const week = Math.floor(daysDifference / 7) + 1;

      this.currentWeekNumber = week;
      console.log(`[calculateCurrentWeek] Calculated current week: ${this.currentWeekNumber}`);

    } catch (e) {
      console.error("[calculateCurrentWeek] Error parsing start date:", e);
      this.currentWeekNumber = 1; // 如果日期格式错误等异常，则默认为1
    }
  }

  private syncSemesterToAppStorage(semester: Semester): void {
    AppStorage.Set(AppSettings.CURRENT_SEMESTER_ID_KEY, semester.id);
    AppStorage.Set(AppSettings.CURRENT_SEMESTER_START_DATE_KEY, semester.startDate);
    AppStorage.Set(AppSettings.CURRENT_SEMESTER_TOTAL_WEEKS_KEY, semester.totalWeeks);
    console.log(`[SettingsViewModel] Synced semester ${semester.id} to AppStorage.`);
    // --- 3. 触发：当学期信息同步后，重新计算当前周数 ---
    this.calculateCurrentWeek();
  }

  public switchActiveSemester(semesterId: number): void {
    const selectedSemester = this.semesters.find(s => s.id === semesterId);
    if (selectedSemester) {
      this.syncSemesterToAppStorage(selectedSemester);
    }
  }

  async init(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const response = await httpUtil.get<Semester[]>('/semesters');
      this.semesters = response.data;
      let activeId = AppStorage.Get<number>(AppSettings.CURRENT_SEMESTER_ID_KEY);
      let targetSemester = this.semesters.find(s => s.id === activeId);

      if (!targetSemester) {
        targetSemester = this.semesters.find(s => s.id === 1) || this.semesters[0];
      }

      if (targetSemester) {
        this.syncSemesterToAppStorage(targetSemester);
      } else {
        this.errorMessage = '无法加载学期数据';
      }
    } catch (err) {
      this.errorMessage = `初始化设置失败: ${(err as Error).message}`;
    } finally {
      this.isLoading = false;
    }
  }

  public async updateSemesterDetails(semesterId: number, newStartDate: string, newTotalWeeks: number): Promise<void> {
    this.isLoading = true;
    try {
      const updateDTO: SemesterUpdateDTO = { startDate: newStartDate, totalWeeks: newTotalWeeks };
      await httpUtil.put<object>(`/semesters/${semesterId}`, updateDTO);
      await this.init(); // 更新成功后，重新初始化以获取最新数据并重新计算周数
      promptAction.showToast({ message: '学期信息更新成功' });
    } catch (err) {
      promptAction.showToast({ message: `更新学期信息异常: ${(err as Error).message}` });
    } finally {
      this.isLoading = false;
    }
  }
}