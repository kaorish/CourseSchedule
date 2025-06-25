import { httpUtil } from '../utils/HttpUtil';
import { CourseInfo, WeeklyCourseVO } from '../model/WeeklyCourseVO';
import { AppSettings } from '../common/AppSettings'; // ★★★ 1. 导入 AppSettings

class GetWeeklyCourseParams {
  semesterId: number = 0;
  week: number = 0;
}

@Observed
export class WeeklyCourseViewModel {
  currentWeek: number = 1;
  // ★★★ 不再需要在此处单独管理 semesterId，它将从全局AppStorage获取 ★★★
  // semesterId: number = 1;
  weeklyCourseData: WeeklyCourseVO | null = null;
  isLoading: boolean = false;
  errorMessage: string = '';

  // fetchAndSetData 和 loadWeeklyCourses 已被合并和简化
  async loadWeeklyCourses() {
    if (this.isLoading) {
      console.log('Course loading is already in progress.');
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      // ★★★ 3. 从 AppStorage 中获取当前用户选择的学期 ID ★★★
      const currentSemesterId = AppStorage.Get<number>(AppSettings.CURRENT_SEMESTER_ID_KEY);

      // 如果用户还未在设置页选择过学期
      if (currentSemesterId === undefined || currentSemesterId === -1) {
        this.errorMessage = '请先在“设置”页面选择一个学期';
        this.isLoading = false; // 结束加载状态
        return;
      }

      const params = new GetWeeklyCourseParams();
      params.semesterId = currentSemesterId; // ★★★ 4. 使用从 AppStorage 获取的 ID ★★★
      params.week = this.currentWeek;

      console.log(`Requesting courses for semester ${params.semesterId}, week ${params.week}`);
      const response = await httpUtil.get<WeeklyCourseVO>('/courses', params);

      this.weeklyCourseData = response.data;
      console.log('Courses loaded successfully.');

    } catch (err) {
      const error = err as Error;
      this.errorMessage = `加载第${this.currentWeek}周课程失败: ${error.message}`;
      console.error(this.errorMessage);
    } finally {
      this.isLoading = false;
    }
  }

  public onWeekChange(index: number, startWeek: number): void {
    const newWeek = index + startWeek;
    if (newWeek !== this.currentWeek) {
      this.currentWeek = newWeek;
      this.weeklyCourseData = null; // 切换时先清空旧数据
      this.loadWeeklyCourses(); // 直接调用已包含完整逻辑的加载方法
    }
  }

  public getCourseAtPosition(dayIndex: number, startPeriod: number): CourseInfo | null {
    if (!this.weeklyCourseData || !this.weeklyCourseData.courses) {
      return null;
    }
    const dayOfWeek = dayIndex + 1;
    return this.weeklyCourseData.courses.find(course =>
    course.dayOfWeek === dayOfWeek && course.startPeriod === startPeriod
    ) || null;
  }
}