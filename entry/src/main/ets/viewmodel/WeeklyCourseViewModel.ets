// src/main/ets/viewmodel/WeeklyCourseViewModel.ts (最终修正版)
import { httpUtil } from '../utils/HttpUtil';
import { CourseInfo, WeeklyCourseVO } from '../model/WeeklyCourseVO';

class GetWeeklyCourseParams {
  semesterId: number = 0;
  week: number = 0;
}

@Observed
export class WeeklyCourseViewModel {
  currentWeek: number = 1;
  semesterId: number = 1;
  weeklyCourseData: WeeklyCourseVO | null = null;
  isLoading: boolean = false;
  errorMessage: string = '';

  // ★★★ 修正点：将async/await逻辑提取到独立的私有方法中 ★★★
  private async fetchAndSetData() {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const params = new GetWeeklyCourseParams();
      params.semesterId = this.semesterId;
      params.week = this.currentWeek;

      // 在这里我们知道返回的一定是WeeklyCourseVO
      const response = await httpUtil.get<WeeklyCourseVO>('/courses', params);
      this.weeklyCourseData = response.data;

    } catch (err) {
      const error = err as Error;
      this.errorMessage = `加载第${this.currentWeek}周课程失败: ${error.message}`;
      console.error(this.errorMessage);
    } finally {
      this.isLoading = false;
    }
  }

  // loadWeeklyCourses现在只是一个简单的调用入口
  async loadWeeklyCourses() {
    // 防止在前一个请求未完成时发起新请求
    if (this.isLoading) {
      console.log('Course loading is already in progress.');
      return;
    }

    // ★★★ 核心修正点 2：在发起请求前，才设置isLoading为true ★★★
    this.isLoading = true;
    this.errorMessage = '';

    try {
      const params = new GetWeeklyCourseParams();
      params.semesterId = this.semesterId;
      params.week = this.currentWeek;

      console.log(`Requesting courses for semester ${params.semesterId}, week ${params.week}`); // 添加日志，方便调试
      const response = await httpUtil.get<WeeklyCourseVO>('/courses', params);

      // 成功获取数据后，更新UI状态
      this.weeklyCourseData = response.data;
      console.log('Courses loaded successfully.');

    } catch (err) {
      const error = err as Error;
      this.errorMessage = `加载第${this.currentWeek}周课程失败: ${error.message}`;
      console.error(this.errorMessage);
    } finally {
      // 无论成功还是失败，最终都要结束加载状态
      this.isLoading = false;
    }
  }

  // onWeekChange现在也只是更新状态并调用
  public onWeekChange(index: number, startWeek: number): void {
    const newWeek = index + startWeek;
    if (newWeek !== this.currentWeek) {
      this.currentWeek = newWeek;
      this.weeklyCourseData = null; // 切换时先清空旧数据，避免闪烁
      this.fetchAndSetData();
    }
  }

  /**
   * 根据位置信息查找课程
   * @param dayIndex 星期几的索引 (0-6)
   * @param startPeriod 开始节次 (1-10)
   * @returns 找到的课程信息，或null
   */
  public getCourseAtPosition(dayIndex: number, startPeriod: number): CourseInfo | null {
    if (!this.weeklyCourseData || !this.weeklyCourseData.courses) {
      return null;
    }
    // dayIndex是0-6，而后端dayOfWeek是1-7
    const dayOfWeek = dayIndex + 1;
    return this.weeklyCourseData.courses.find(course =>
    course.dayOfWeek === dayOfWeek && course.startPeriod === startPeriod
    ) || null;
  }
}