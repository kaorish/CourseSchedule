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
      let targetSemester = this.semesters.find((s: Semester) => s.id === activeId);

      if (!targetSemester) {
        targetSemester = this.semesters.find((s: Semester) => s.id === 1) ?? this.semesters[0];
      }

      if (targetSemester) {
        await this.setCurrentSemester(targetSemester.id);
      } else {
        this.errorMessage = '无法加载学期数据';
      }
    } catch (err) {
      this.errorMessage = `初始化设置失败: ${(err as Error).message}`;
    } finally {
      this.isLoading = false;
    }
  }

  async setCurrentSemester(semesterId: number): Promise<void> {
    const selectedSemester = this.semesters.find((s: Semester) => s.id === semesterId);
    if (selectedSemester) {
      this.currentSemesterId = selectedSemester.id;
      this.startDate = selectedSemester.startDate;
      this.totalWeeks = selectedSemester.totalWeeks;

      AppStorage.Set(AppSettings.CURRENT_SEMESTER_ID_KEY, selectedSemester.id);
      AppStorage.Set(AppSettings.CURRENT_SEMESTER_START_DATE_KEY, selectedSemester.startDate);
      AppStorage.Set(AppSettings.CURRENT_SEMESTER_TOTAL_WEEKS_KEY, selectedSemester.totalWeeks);

      this.calculateCurrentWeek();
    }
  }

  /**
   * 新增：更新学期详情的核心方法 (此方法在您当前版本中缺失)
   * @param semesterId 要更新的学期ID
   * @param updateData 包含新开始日期或新总周数的对象
   */
  async updateSemesterDetails(semesterId: number, updateData: Partial<SemesterUpdateDTO>): Promise<void> {
    if (!semesterId || semesterId === -1) {
      promptAction.showToast({ message: '无效的学期ID' });
      return;
    }
    this.isLoading = true;
    try {
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
      } else {
        const diffDays = Math.floor(diff / (1000 * 60 * 60 * 24));
        const week = Math.floor(diffDays / 7) + 1;
        this.currentWeekNumber = week;
      }
      AppStorage.Set(AppSettings.CALCULATED_CURRENT_WEEK_KEY, this.currentWeekNumber);
    } catch (e) {
      this.currentWeekNumber = 1;
      AppStorage.Set(AppSettings.CALCULATED_CURRENT_WEEK_KEY, 1);
    }
  }
}