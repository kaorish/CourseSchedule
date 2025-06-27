import { httpUtil } from '../utils/HttpUtil';
import { Semester } from '../model/Semester';
import { SemesterUpdateDTO } from '../model/SemesterUpdateDTO';
import promptAction from '@ohos.promptAction';
import { AppSettings } from '../common/AppSettings';
import { SharedPreferenceManager } from '../utils/SharedPreferenceManager'; // 导入新创建的管理器
import { common } from '@kit.AbilityKit'; // 导入 common

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

  async init(context: common.UIAbilityContext): Promise<void> {
    console.log('[SettingsViewModel] Initializing...');
    this.isLoading = true;
    this.errorMessage = '';
    try {
      // 1. 从服务器获取所有学期列表
      const response = await httpUtil.get<Semester[]>('/semesters');
      if (!response.status || !response.data) {
        throw new Error(response.msg || '获取学期列表失败');
      }
      this.semesters = response.data;
      console.log(`[SettingsViewModel] Fetched ${this.semesters.length} semesters.`);

      // 2. 确定要使用的学期ID
      let activeId = AppStorage.Get<number>(AppSettings.CURRENT_SEMESTER_ID_KEY);
      let targetSemester = this.semesters.find((s: Semester) => s.id === activeId);

      // 3. 如果找不到已存储的学期（比如首次启动或数据丢失），则使用默认学期
      if (!targetSemester) {
        console.log(`[SettingsViewModel] No valid semester found for stored ID: ${activeId}. Falling back to default.`);
        // 尝试ID为1的学期，如果还没有，就用列表的第一个
        targetSemester = this.semesters.find((s: Semester) => s.id === 1) ?? this.semesters[0];
      }

      // 4. 如果最终找到了一个有效的学期，则设置它为当前学期
      if (targetSemester) {
        // 调用setCurrentSemester来更新所有相关状态和AppStorage
        await this.setCurrentSemester(targetSemester.id, context);
      } else {
        // 如果连一个学期数据都没有
        this.errorMessage = '无法加载任何学期数据';
        console.error(this.errorMessage);
      }
    } catch (err) {
      const errorMessage = `初始化设置失败: ${(err as Error).message}`;
      this.errorMessage = errorMessage;
      console.error(errorMessage);
    } finally {
      this.isLoading = false;
    }
  }

  async setCurrentSemester(semesterId: number, context: common.UIAbilityContext): Promise<void> {
    const selectedSemester = this.semesters.find((s: Semester) => s.id === semesterId);
    if (selectedSemester) {
      this.currentSemesterId = selectedSemester.id;
      this.startDate = selectedSemester.startDate;
      this.totalWeeks = selectedSemester.totalWeeks;

      // 使用 SharedPreferenceManager 保存学期ID
      await SharedPreferenceManager.setCurrentSemesterId(context, selectedSemester.id);

      // AppStorage 仍然可以用于UI的快速响应
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
  async updateSemesterDetails(semesterId: number, updateData: Partial<SemesterUpdateDTO>, context: common.UIAbilityContext): Promise<void> {
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
      await this.init(context);
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
      // 确保在加载失败时也更新存储
      AppStorage.Set(AppSettings.CALCULATED_CURRENT_WEEK_KEY, 1);
      return;
    }
    try {
      const startDate = new Date(this.startDate);
      const now = new Date();
      startDate.setHours(0, 0, 0, 0);
      now.setHours(0, 0, 0, 0);
      const diff = now.getTime() - startDate.getTime();

      let week = 1; // 默认第一周

      if (diff >= 0) {
        const diffDays = Math.floor(diff / (1000 * 60 * 60 * 24));
        week = Math.floor(diffDays / 7) + 1;
      }

      // ★★★ 核心修改：保证周数在 1 到 totalWeeks (或20) 之间 ★★★
      const maxWeeks = this.totalWeeks > 0 ? this.totalWeeks : 20; // 使用学期总周数，如果没有则用20作为上限
      this.currentWeekNumber = Math.max(1, Math.min(week, maxWeeks));

      // 将修正后的有效周数写入AppStorage
      AppStorage.Set(AppSettings.CALCULATED_CURRENT_WEEK_KEY, this.currentWeekNumber);
      console.log(`[SettingsViewModel] Week calculated. StartDate: ${this.startDate}, TotalWeeks: ${this.totalWeeks}, Calculated Week: ${this.currentWeekNumber}`);

    } catch (e) {
      this.currentWeekNumber = 1;
      AppStorage.Set(AppSettings.CALCULATED_CURRENT_WEEK_KEY, 1);
    }
  }
}