import { httpUtil } from '../utils/HttpUtil'; // 导入网络请求工具
import { Semester } from '../model/Semester';       // 导入学期数据模型
import { SemesterUpdateDTO } from '../model/SemesterUpdateDTO'; // 导入学期更新数据传输对象
import promptAction from '@ohos.promptAction';    // 导入提示工具
import { AppSettings } from '../common/AppSettings'; // 导入我们的键定义

/**
 * SettingsViewModel 类
 * 负责管理设置页面的状态、数据获取和更新逻辑。
 */
@Observed // 使其可观察，当内部状态变化时，UI能自动刷新
export class SettingsViewModel {
  // 当前已加载的所有学期列表
  semesters: Semester[] = [];

  // 当前选中的学期ID，用于后端交互和UI显示当前学期信息
  currentSemesterId: number = 0;
  // 当前学期的开始日期，从后端获取并显示
  startDate: string = '加载中...';
  // 当前学期的总周数，从后端获取并显示
  totalWeeks: number = 0;

  // 以下为静态显示或本地控制的设置项，不涉及后端修改，但由ViewModel统一管理
  // 当前周数 (根据需求，此处为静态显示，不自动计算)
  currentWeekNumber: number = 1;
  // 是否显示周末 (本地开关状态)
  showWeekend: boolean = true;
  // 是否显示非本周课程 (本地开关状态)
  showNonCurrentWeekCourses: boolean = false;

  // 注意：advanceMinutes 属性已从此 ViewModel 中移除。
  // 它现在由 AppStorage 和 Settings.ets 中的 @StorageLink 直接管理。

  // 加载状态，用于显示加载指示器
  isLoading: boolean = false;
  // 错误信息，用于显示网络请求或数据处理错误
  errorMessage: string = '';

  // 默认初始加载的学期ID，可根据实际情况调整，例如加载最新学期
  private readonly DEFAULT_SEMESTER_ID = 1;

  /**
   * 初始化ViewModel，执行学期数据加载。
   * 在页面 aboutToAppear 生命周期中调用。
   */
  async init(): Promise<void> {
    this.isLoading = true; // 开始加载
    this.errorMessage = ''; // 清空之前的错误信息
    try {
      await this.fetchSemesters(); // 获取所有学期
      // 如果有学期数据，则尝试设置默认学期或第一个学期为当前学期
      if (this.semesters.length > 0) {
        const defaultSemester = this.semesters.find(s => s.id === this.DEFAULT_SEMESTER_ID) || this.semesters[0];
        this.setCurrentSemester(defaultSemester.id); // 设置当前学期
      }
    } catch (err) {
      const error = err as Error;
      this.errorMessage = `初始化设置失败: ${error.message}`;
      console.error(this.errorMessage);
      promptAction.showToast({ message: this.errorMessage, duration: 2000 }); // 弹出错误提示
    } finally {
      this.isLoading = false; // 结束加载
    }
  }

  /**
   * 从后端获取所有学期列表。
   */
  async fetchSemesters(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      // 调用 HttpUtil 发送 GET 请求到 /api/semesters
      const response = await httpUtil.get<Semester[]>('/semesters');
      if (response.status) {
        this.semesters = response.data; // 更新学期列表
        console.log('Semesters loaded:', this.semesters);
      } else {
        this.errorMessage = response.msg || '加载学期列表失败';
        promptAction.showToast({ message: this.errorMessage, duration: 2000 });
      }
    } catch (err) {
      const error = err as Error;
      this.errorMessage = `获取学期列表异常: ${error.message}`;
      console.error(this.errorMessage);
      promptAction.showToast({ message: this.errorMessage, duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 设置当前选中的学期，并更新其开始日期和总周数。
   * @param semesterId 要设置为当前学期的ID。
   */
  setCurrentSemester(semesterId: number): void {
    const selectedSemester = this.semesters.find(s => s.id === semesterId);
    if (selectedSemester) {
      this.currentSemesterId = selectedSemester.id;
      this.startDate = selectedSemester.startDate;
      this.totalWeeks = selectedSemester.totalWeeks;
      console.log(`Current semester set to: ${selectedSemester.name}`);
    } else {
      console.warn(`Semester with ID ${semesterId} not found.`);
      this.errorMessage = '选择的学期不存在';
      promptAction.showToast({ message: this.errorMessage, duration: 2000 });
    }
  }

  /**
   * 更新指定学期的开始日期和总周数到后端。
   * @param semesterId 要更新的学期ID。
   * @param newStartDate 新的开始日期，格式 "YYYY-MM-DD"。
   * @param newTotalWeeks 新的总周数。
   */
  async updateSemesterDetails(semesterId: number, newStartDate: string, newTotalWeeks: number): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const updateDTO: SemesterUpdateDTO = {
        startDate: newStartDate,
        totalWeeks: newTotalWeeks
      };
      // 调用 HttpUtil 发送 PUT 请求到 /api/semesters/{id}
      const response = await httpUtil.put<Semester>(`/semesters/${semesterId}`, updateDTO);
      if (response.status) {
        // 成功后，更新本地学期列表中的对应学期信息
        const updatedSemesterIndex = this.semesters.findIndex(s => s.id === semesterId);
        if (updatedSemesterIndex !== -1) {
          this.semesters[updatedSemesterIndex].startDate = newStartDate;
          this.semesters[updatedSemesterIndex].totalWeeks = newTotalWeeks;
        }
        // 如果更新的是当前选中的学期，则同步更新UI上显示的日期和周数
        if (this.currentSemesterId === semesterId) {
          this.startDate = newStartDate;
          this.totalWeeks = newTotalWeeks;
        }
        promptAction.showToast({ message: '学期信息更新成功', duration: 1500 });
        console.log('Semester updated successfully.');
      } else {
        this.errorMessage = response.msg || '更新学期信息失败';
        promptAction.showToast({ message: this.errorMessage, duration: 2000 });
      }
    } catch (err) {
      const error = err as Error;
      this.errorMessage = `更新学期信息异常: ${error.message}`;
      console.error(this.errorMessage);
      promptAction.showToast({ message: this.errorMessage, duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }
}