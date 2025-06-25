// 文件路径: entry/src/main/ets/viewmodel/WeeklyCourseViewModel.ets

import { httpUtil } from '../utils/HttpUtil';
import { CourseInfo, WeeklyCourseVO } from '../model/WeeklyCourseVO';
import { AppSettings } from '../common/AppSettings';

class GetWeeklyCourseParams {
  semesterId: number = 0;
  week: number = 0;
}

@Observed
export class WeeklyCourseViewModel {
  currentWeek: number = 1;
  weeklyCourseData: WeeklyCourseVO | null = null;
  isLoading: boolean = false;
  errorMessage: string = '';

  async loadWeeklyCourses() {
    // --- 核心修改在这里 ---
    // 1. 先尝试从 AppStorage 中获取学期ID
    let semesterId = AppStorage.Get<number>(AppSettings.CURRENT_SEMESTER_ID_KEY);
    console.log(`[WeeklyCourseViewModel] Attempting to load. Found semesterId in AppStorage: ${semesterId}`);

    // 2. 如果从 AppStorage 中获取的ID是 undefined 或无效值(-1)，则强制使用默认值 1
    //    这样就保证了首次进入APP时，即使AppStorage还未准备好，也能用默认学期ID去请求数据。
    if (semesterId === undefined || semesterId === -1) {
      semesterId = 1; //  <---  强制使用默认值
      console.log(`[WeeklyCourseViewModel] semesterId from AppStorage is invalid, falling back to default ID: ${semesterId}`);
    }
    // --- 修改结束 ---


    if (this.isLoading) {
      console.log('Course loading is already in progress.');
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const params = new GetWeeklyCourseParams();
      // 使用我们保证有效的 semesterId
      params.semesterId = semesterId;
      params.week = this.currentWeek;

      console.log(`[WeeklyCourseViewModel] Requesting courses for semester ${params.semesterId}, week ${params.week}`);
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