// src/main/ets/pages/ApiTestPage.ets

import { httpUtil } from '../utils/HttpUtil'
import { BusinessError } from '@ohos.base'
// 确保导入路径正确，并且所有用到的class都是export的
import { Semester } from '../model/Semester'
import { WeeklyCourseVO, CourseInfo } from '../model/WeeklyCourseVO'

// --- 为所有接口的参数和返回值的模型创建明确的class或interface ---

class ScheduleManageVO {
  scheduleId: number = 0
  courseName: string = ''
  teacher: string = ''
  location: string = ''
  dayOfWeekText: string = ''
  timeText: string = ''
  weeksText: string = ''
  color: string = ''
}

class ScheduleDetailVO {
  courseName: string = ''
  teacher: string = ''
  color: string = ''
  location: string = ''
  dayOfWeek: number = 0
  startPeriod: number = 0
  endPeriod: number = 0
  weeks: number[] = []
}

class AddScheduleParams {
  semesterId: number = 0
  courseName: string = ''
  teacher: string = ''
  color: string = ''
  location: string = ''
  dayOfWeek: number = 0
  startPeriod: number = 0
  endPeriod: number = 0
  weeks: number[] = []
}

class UpdateSemesterParams {
  startDate: string = ''
  totalWeeks: number = 0
}

class UpdateScheduleParams {
  courseName: string = ''
  teacher: string = ''
  color: string = ''
  location: string = ''
  dayOfWeek: number = 0
  startPeriod: number = 0
  endPeriod: number = 0
  weeks: number[] = []
}

// 为GET请求的URL参数创建明确类型
class GetWeeklyCourseParams {
  semesterId: number = 0
  week: number = 0
}

class GetTodayCourseParams {
  semesterId: number = 0
}

class GetScheduleListParams {
  semesterId: number = 0
}


@Entry
@Component
struct ApiTestPage {
  @State resultJson: string = '点击按钮开始测试...';
  @State isLoading: boolean = false;

  async runTest<T>(apiCall: () => Promise<T>) {
    this.isLoading = true;
    this.resultJson = '正在请求...';
    try {
      const response = await apiCall();
      this.resultJson = JSON.stringify(response, null, 2);
    } catch (err) {
      const error = err as Error;
      this.resultJson = `请求失败: \n${error.message}`;
    } finally {
      this.isLoading = false;
    }
  }

  // --- GET 请求测试 ---
  private handleGetSemesters() {
    this.runTest(() => httpUtil.get<Semester[]>('/semesters'))
  }

  private handleGetWeeklyCourses() {
    const params = new GetWeeklyCourseParams();
    params.semesterId = 1;
    params.week = 8;
    this.runTest(() => httpUtil.get<WeeklyCourseVO>('/courses', params))
  }

  private handleGetTodayCourses() {
    const params = new GetTodayCourseParams();
    params.semesterId = 1;
    this.runTest(() => httpUtil.get<CourseInfo[]>('/courses/today', params))
  }

  private handleGetScheduleList() {
    const params = new GetScheduleListParams();
    params.semesterId = 2;
    this.runTest(() => httpUtil.get<ScheduleManageVO[]>('/schedules', params))
  }

  private handleGetScheduleDetail() {
    this.runTest(() => httpUtil.get<ScheduleDetailVO>('/schedules/16'))
  }

  // --- POST 请求测试 ---
  private handleAddSchedule() {
    const params = new AddScheduleParams();
    params.semesterId = 1;
    params.courseName = '鸿蒙最终测试课';
    params.teacher = 'Final-Tester';
    params.color = '#E91E63';
    params.location = '零报错教室';
    params.dayOfWeek = 2;
    params.startPeriod = 5;
    params.endPeriod = 6;
    params.weeks = [1, 3, 5, 19, 18, 17, 16];
    this.runTest(() => httpUtil.post<object>('/schedules', params))
  }

  // --- PUT 请求测试 ---
  private handleUpdateSemester() {
    const params = new UpdateSemesterParams();
    params.startDate = '2022-09-01';
    params.totalWeeks = 18;
    this.runTest(() => httpUtil.put<object>('/semesters/6', params))
  }

  private handleUpdateSchedule() {
    const params = new UpdateScheduleParams();
    params.courseName = '鸿蒙测试课(最终修改版)';
    params.teacher = 'Tester-San-Final';
    params.color = '#4CAF50';
    params.location = '最终测试教室';
    params.dayOfWeek = 2;
    params.startPeriod = 3;
    params.endPeriod = 4;
    params.weeks = [1, 2, 3, 4, 5];
    // 注意：这里的ID需要是你数据库中真实存在的schedule ID
    this.runTest(() => httpUtil.put<object>('/schedules/103', params))
  }

  // --- DELETE 请求测试 ---
  private handleDeleteSchedule() {
    // 注意：这里的ID需要是你数据库中真实存在的schedule ID
    this.runTest(() => httpUtil.delete<object>('/schedules/103'))
  }

  build() {
    Scroll() {
      Column({ space: 10 }) {
        Text('后端API接口测试页面')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .padding({ top: 20, bottom: 10 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
          TestButton({ label: 'GET 所有学期', onButtonClick: (): void => this.handleGetSemesters() })
          TestButton({ label: 'GET 周课程 (s1,w8)', onButtonClick: (): void => this.handleGetWeeklyCourses() })
          TestButton({ label: 'GET 今日课程 (s1)', onButtonClick: (): void => this.handleGetTodayCourses() })
          TestButton({ label: 'GET 管理列表 (s2)', onButtonClick: (): void => this.handleGetScheduleList() })
          TestButton({ label: 'GET 课程详情 (id16)', onButtonClick: (): void => this.handleGetScheduleDetail() })
          TestButton({ label: 'POST 添加课程', onButtonClick: (): void => this.handleAddSchedule() })
          TestButton({ label: 'PUT 修改学期 (id6)', onButtonClick: (): void => this.handleUpdateSemester() })
          TestButton({ label: 'PUT 修改课程 (id103)', onButtonClick: (): void => this.handleUpdateSchedule() })
          TestButton({ label: 'DELETE 删除课程 (id103)', onButtonClick: (): void => this.handleDeleteSchedule() })
        }
        .padding(10)
        .width('100%')

        Divider().color(0xCCCCCC).strokeWidth(1).margin({ top: 10, bottom: 10 })

        Text('API返回结果:')
          .fontSize(18)
          .width('100%')
          .textAlign(TextAlign.Start)

        if (this.isLoading) {
          LoadingProgress().width(50).height(50).margin(20)
        } else {
          Text(this.resultJson)
            .width('100%')
            .padding(10)
            .backgroundColor(0xF1F3F5)
            .borderRadius(8)
            .fontFamily('Consolas, Monaco, monospace')
            .textAlign(TextAlign.Start)
        }
      }
      .width('100%')
      .padding({ left: 15, right: 15, bottom: 20 })
    }
    .scrollBar(BarState.Auto)
  }
}

@Component
struct TestButton {
  label: string = '';
  onButtonClick: () => void = () => {};

  build() {
    Button(this.label)
      .type(ButtonType.Capsule)
      .margin(5)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#007DFF')
      .onClick(() => {
        if (this.onButtonClick) {
          this.onButtonClick();
        }
      })
  }
}