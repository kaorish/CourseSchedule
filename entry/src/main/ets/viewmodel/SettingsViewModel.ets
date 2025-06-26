import { httpUtil } from '../utils/HttpUtil';
import { Semester } from '../model/Semester';
import { SemesterUpdateDTO } from '../model/SemesterUpdateDTO';
import promptAction from '@ohos.promptAction';
import { AppSettings } from '../common/AppSettings';

@Observed
export class SettingsViewModel {
  semesters: Semester[] = [];
  currentSemesterId: number = -1;
  startDate: string = '加载中...';
  totalWeeks: number = 0;
  isLoading: boolean = false;
  errorMessage: string = '';
  currentWeekNumber: number = 1;
  showWeekend: boolean = true;
  showNonCurrentWeekCourses: boolean = false;

  async init(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const response = await httpUtil.get<Semester[]>('/semesters');
      if (!response.status) {
        throw new Error(response.msg || '获取学期列表失败');
      }
      this.semesters = response.data;

      let activeId = AppStorage.Get<number>(AppSettings.CURRENT_SEMESTER_ID_KEY);

      // 最终修正：为 find 方法的参数 s 显式声明类型为 Semester
      // 这将解决 API 16 上的类型推断错误
      let targetSemester = this.semesters.find((s: Semester) => s.id === activeId);

      if (!targetSemester) {
        // 同样为这里的 find 方法参数 s 显式声明类型
        targetSemester = this.semesters.find((s: Semester) => s.id === 1) ?? this.semesters[0];
      }

      if (targetSemester) {
        await this.setCurrentSemester(targetSemester.id);
      } else {
        this.errorMessage = '无法加载学期数据';
      }
    } catch (err) {
      this.errorMessage = `初始化设置失败: ${(err as Error).message}`;
      console.error(this.errorMessage);
    } finally {
      this.isLoading = false;
    }
  }

  async setCurrentSemester(semesterId: number): Promise<void> {
    // 最终修正：为 find 方法的参数 s 显式声明类型
    const selectedSemester = this.semesters.find((s: Semester) => s.id === semesterId);
    if (selectedSemester) {
      this.currentSemesterId = selectedSemester.id;
      this.startDate = selectedSemester.startDate;
      this.totalWeeks = selectedSemester.totalWeeks;

      AppStorage.Set(AppSettings.CURRENT_SEMESTER_ID_KEY, selectedSemester.id);
      AppStorage.Set(AppSettings.CURRENT_SEMESTER_START_DATE_KEY, selectedSemester.startDate);
      AppStorage.Set(AppSettings.CURRENT_SEMESTER_TOTAL_WEEKS_KEY, selectedSemester.totalWeeks);

      this.calculateCurrentWeek();
      console.log(`[SettingsViewModel] Semester changed and saved: ID=${selectedSemester.id}`);
    } else {
      console.warn(`[SettingsViewModel] Semester with ID ${semesterId} not found.`);
    }
  }

  async updateSemesterDetails(semesterId: number, updateData: Partial<SemesterUpdateDTO>): Promise<void> {
    if (!semesterId || semesterId === -1) {
      promptAction.showToast({ message: '无效的学期ID' });
      return;
    }
    this.isLoading = true;
    try {
      // 最终修正：为 find 方法的参数 s 显式声明类型
      const currentSemester = this.semesters.find((s: Semester) => s.id === semesterId);
      if (!currentSemester) {
        throw new Error("未找到当前学期");
      }
      const updateDTO: SemesterUpdateDTO = {
        startDate: updateData.startDate ?? currentSemester.startDate,
        totalWeeks: updateData.totalWeeks ?? currentSemester.totalWeeks,
      };
      await httpUtil.put<object>(`/semesters/${semesterId}`, updateDTO);
      await this.init();
      promptAction.showToast({ message: '学期信息更新成功' });
    } catch (err) {
      const errorMessage = `更新学期信息异常: ${(err as Error).message}`;
      this.errorMessage = errorMessage;
      promptAction.showToast({ message: errorMessage });
    } finally {
      this.isLoading = false;
    }
  }

  calculateCurrentWeek(): void {
    if (!this.startDate || this.startDate === '加载中...') {
      this.currentWeekNumber = 1;
      return;
    }
    try {
      const startDate = new Date(this.startDate);
      const now = new Date();
      startDate.setHours(0, 0, 0, 0);
      now.setHours(0, 0, 0, 0);
      const diff = now.getTime() - startDate.getTime();
      if (diff < 0) {
        this.currentWeekNumber = 1;
        return;
      }
      const diffDays = Math.floor(diff / (1000 * 60 * 60 * 24));
      const week = Math.floor(diffDays / 7) + 1;
      this.currentWeekNumber = week;
    } catch (e) {
      console.error("Error calculating current week: ", e);
      this.currentWeekNumber = 1;
    }
  }
}