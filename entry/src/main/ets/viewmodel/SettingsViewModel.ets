import { httpUtil } from '../utils/HttpUtil';
import { Semester } from '../model/Semester';
import { SemesterUpdateDTO } from '../model/SemesterUpdateDTO';
import promptAction from '@ohos.promptAction';
import { AppSettings } from '../common/AppSettings';


@Observed
export class SettingsViewModel {
  semesters: Semester[] = [];

  // 这些属性将通过 AppStorage 加载，并由 @Observed 驱动UI更新
  currentSemesterId: number = -1;
  startDate: string = '加载中...';
  totalWeeks: number = 0;

  isLoading: boolean = false;
  errorMessage: string = '';

  // 其他属性保持不变
  currentWeekNumber: number = 1;
  showWeekend: boolean = true;
  showNonCurrentWeekCourses: boolean = false;

  async init(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      // 1. 从网络获取所有可用学期的列表
      const response = await httpUtil.get<Semester[]>('/semesters');
      if (!response.status) {
        throw new Error(response.msg || '获取学期列表失败');
      }
      this.semesters = response.data;
      console.log(`[SettingsViewModel] Fetched ${this.semesters.length} semesters.`);

      // 2. 从 AppStorage 获取当前激活的学期ID
      let activeId = AppStorage.Get<number>(AppSettings.CURRENT_SEMESTER_ID_KEY);
      console.log(`[SettingsViewModel] Found stored semester ID: ${activeId}`);

      // 3. 确定最终要使用的学期
      //    - 检查存储的ID是否有效（即是否存在于刚获取的学期列表中）
      let targetSemester = this.semesters.find(s => s.id === activeId);

      //    - 如果存储的ID无效（比如刚安装应用，或者该学期已被删除）
      if (!targetSemester) {
        console.log(`[SettingsViewModel] Stored semester ID ${activeId} is invalid or not found. Finding default.`);
        // 则使用ID为1的学期作为备用默认值
        targetSemester = this.semesters.find(s => s.id === 1);
        // 如果连ID为1的学期都没有，就用列表的第一个
        if (!targetSemester && this.semesters.length > 0) {
          targetSemester = this.semesters[0];
        }
      }

      // 4. 如果找到了一个确切的学期，就用它的信息更新状态和本地存储
      if (targetSemester) {
        console.log(`[SettingsViewModel] Setting active semester to ID: ${targetSemester.id}`);
        await this.setCurrentSemester(targetSemester.id);
      } else {
        console.error('[SettingsViewModel] No available semesters to set.');
        this.errorMessage = '无法加载学期数据';
      }

    } catch (err) {
      this.errorMessage = `初始化设置失败: ${(err as Error).message}`;
      console.error(this.errorMessage);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 切换当前学期，这个方法现在是更新状态和存储的唯一入口
   */
  async setCurrentSemester(semesterId: number): Promise<void> {
    const selectedSemester = this.semesters.find(s => s.id === semesterId);
    if (selectedSemester) {
      // 更新ViewModel的属性，UI会因为@Observed而自动刷新
      this.currentSemesterId = selectedSemester.id;
      this.startDate = selectedSemester.startDate;
      this.totalWeeks = selectedSemester.totalWeeks;

      // 将新选择的学期信息写入AppStorage，实现持久化
      AppStorage.Set(AppSettings.CURRENT_SEMESTER_ID_KEY, selectedSemester.id);
      AppStorage.Set(AppSettings.CURRENT_SEMESTER_START_DATE_KEY, selectedSemester.startDate);
      AppStorage.Set(AppSettings.CURRENT_SEMESTER_TOTAL_WEEKS_KEY, selectedSemester.totalWeeks);

      console.log(`[SettingsViewModel] Semester changed and saved to AppStorage: ID=${selectedSemester.id}`);
    } else {
      console.warn(`[SettingsViewModel] Semester with ID ${semesterId} not found in the list.`);
    }
  }

  // updateSemesterDetails 方法保持原样，它已经包含了更新成功后刷新列表的逻辑
  async updateSemesterDetails(semesterId: number, newStartDate: string, newTotalWeeks: number): Promise<void> {
    this.isLoading = true;
    try {
      const updateDTO: SemesterUpdateDTO = { startDate: newStartDate, totalWeeks: newTotalWeeks };
      await httpUtil.put<object>(`/semesters/${semesterId}`, updateDTO);

      if (this.currentSemesterId === semesterId) {
        AppStorage.Set(AppSettings.CURRENT_SEMESTER_START_DATE_KEY, newStartDate);
        AppStorage.Set(AppSettings.CURRENT_SEMESTER_TOTAL_WEEKS_KEY, newTotalWeeks);
      }

      await this.init(); // 重新初始化来刷新所有数据
      promptAction.showToast({ message: '学期信息更新成功' });
    } catch (err) {
      this.errorMessage = `更新学期信息异常: ${(err as Error).message}`;
      promptAction.showToast({ message: this.errorMessage });
    } finally {
      this.isLoading = false;
    }
  }
}