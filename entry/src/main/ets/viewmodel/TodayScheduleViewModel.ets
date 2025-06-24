import { httpUtil } from '../utils/HttpUtil';
import { TimeSlot } from '../model/TimeSlot';

/**
 * @description 后端返回的今日课程数据结构
 */
export class TodayCourseResponse {
  scheduleId: number = 0;
  name: string = '';
  teacher: string = '';
  location: string = '';
  color: string = '';
  dayOfWeek: number = 0;
  startPeriod: number = 0;
  endPeriod: number = 0;
  // 添加具体时间字段
  specificStartTime?: string;
  specificEndTime?: string;
}

/**
 * @description 表示每日课表中的一个具体时间段
 */
export interface CourseTimeSegment {
  startTime: string; // 开始时间
  endTime: string; // 结束时间
  session: string; // 节次描述
  courses: TodayCourseResponse[]; // 该时间段的课程
}

/**
 * @description 表示每日课表中的一个时间段分组（上午/下午/晚上）
 */
export interface DailyCourseTimeSlot {
  period: string; // 时间段名称，例如: '上午课程'
  segments: CourseTimeSegment[]; // 该时间段内的具体时间段列表
}

/**
 * @description 定义时间段范围的接口
 */
interface TimeSlotRange {
  slot: DailyCourseTimeSlot;
  periods: number[];
}

class GetTodayCourseParams {
  semesterId: number = 1;
}

@Observed
export class TodayScheduleViewModel {
  todayDate: string = '';
  todayWeekday: string = '';
  dailySchedule: DailyCourseTimeSlot[] = [];
  isLoading: boolean = false;
  errorMessage: string = '';

  private timeSlotsDefinitions: TimeSlot[] = [
    new TimeSlot('1', '08:30', '09:15'), new TimeSlot('2', '09:20', '10:05'),
    new TimeSlot('3', '10:25', '11:10'), new TimeSlot('4', '11:15', '12:00'),
    new TimeSlot('5', '14:00', '14:45'), new TimeSlot('6', '14:50', '15:35'),
    new TimeSlot('7', '15:55', '16:40'), new TimeSlot('8', '16:45', '17:30'),
    new TimeSlot('9', '19:00', '19:45'), new TimeSlot('10', '19:50', '20:35')
  ];

  constructor() {
    this.initDate();
  }

  initDate(): void {
    const now = new Date();
    this.todayDate = this.formatDate(now);
    this.todayWeekday = this.getWeekday(now);
  }

  private formatDate(date: Date): string {
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }

  private getWeekday(date: Date): string {
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    return weekdays[date.getDay()];
  }

  /**
   * ★★★ 核心修正：修改函数签名，让它返回 Promise<TodayCourseResponse[]> ★★★
   */
  public async loadTodayCourses(): Promise<TodayCourseResponse[]> {
    if (this.isLoading) {
      console.log('Today courses loading is already in progress.');
      return []; // 如果正在加载，返回一个空数组
    }

    this.isLoading = true;
    this.errorMessage = '';
    let rawCourses: TodayCourseResponse[] = []; // 定义一个变量来存储结果

    try {
      const params = new GetTodayCourseParams();
      params.semesterId = 1;

      console.log(`Requesting today's courses for semester ${params.semesterId}`);
      const response = await httpUtil.get<TodayCourseResponse[]>('/courses/today', params);

      // 将获取的数据赋值给局部变量
      rawCourses = response.data;

      // 这行代码会更新UI，保持不变
      this.processRawCourses(rawCourses);

      console.log('Today\'s courses loaded successfully.');

    } catch (err) {
      const error = err as Error;
      this.errorMessage = `加载今日课程失败: ${error.message}`;
      console.error(this.errorMessage);
    } finally {
      this.isLoading = false;
    }

    // ★★★ 核心修正：在函数末尾，返回获取到的课程数组 ★★★
    return rawCourses;
  }

  // processRawCourses 及之后的所有方法保持不变...
  private processRawCourses(rawCourses: TodayCourseResponse[]): void {
    const morningSlot: DailyCourseTimeSlot = { period: '上午课程', segments: [] };
    const afternoonSlot: DailyCourseTimeSlot = { period: '下午课程', segments: [] };
    const eveningSlot: DailyCourseTimeSlot = { period: '晚上课程', segments: [] };

    const timeSlotRanges: TimeSlotRange[] = [
      { slot: morningSlot, periods: [1, 2, 3, 4] },
      { slot: afternoonSlot, periods: [5, 6, 7, 8] },
      { slot: eveningSlot, periods: [9, 10] }
    ];

    timeSlotRanges.forEach((range: TimeSlotRange) => {
      const slot = range.slot;
      const periods = range.periods;
      for (let i = 0; i < periods.length; i += 2) {
        const startPeriod = periods[i];
        const endPeriod = periods[i + 1] || startPeriod;
        const segment: CourseTimeSegment = {
          startTime: this.getTimeFromPeriod(startPeriod),
          endTime: this.getEndTimeFromPeriod(endPeriod),
          session: this.getSessionDescription(startPeriod, endPeriod),
          courses: []
        };
        slot.segments.push(segment);
      }
    });

    rawCourses.forEach((course: TodayCourseResponse) => {
      if (course.startPeriod >= 1 && course.startPeriod <= 10 && course.endPeriod >= 1 && course.endPeriod <= 10) {
        course.specificStartTime = this.getTimeFromPeriod(course.startPeriod);
        course.specificEndTime = this.getEndTimeFromPeriod(course.endPeriod);
        let targetSlot: DailyCourseTimeSlot;
        if (course.startPeriod >= 1 && course.startPeriod <= 4) {
          targetSlot = morningSlot;
        } else if (course.startPeriod >= 5 && course.startPeriod <= 8) {
          targetSlot = afternoonSlot;
        } else {
          targetSlot = eveningSlot;
        }
        const matchingSegment = targetSlot.segments.find((segment: CourseTimeSegment) => {
          const segmentStartTime = segment.startTime;
          const segmentEndTime = segment.endTime;
          const courseStartTime = course.specificStartTime;
          const courseEndTime = course.specificEndTime;
          if (courseStartTime && courseEndTime) {
            return (courseStartTime >= segmentStartTime && courseEndTime <= segmentEndTime) ||
              (courseStartTime === segmentStartTime && courseEndTime === segmentEndTime);
          }
          return false;
        });
        if (matchingSegment) {
          matchingSegment.courses.push(course);
        }
      }
    });
    const allSlots: DailyCourseTimeSlot[] = [morningSlot, afternoonSlot, eveningSlot];
    allSlots.forEach((slot: DailyCourseTimeSlot) => {
      slot.segments.forEach((segment: CourseTimeSegment) => {
        segment.courses.sort((a: TodayCourseResponse, b: TodayCourseResponse) => a.startPeriod - b.startPeriod);
      });
    });
    this.dailySchedule = allSlots;
  }

  private getTimeFromPeriod(period: number): string {
    if (period >= 1 && period <= 10) {
      return this.timeSlotsDefinitions[period - 1].startTime;
    }
    return '';
  }

  private getEndTimeFromPeriod(period: number): string {
    if (period >= 1 && period <= 10) {
      return this.timeSlotsDefinitions[period - 1].endTime;
    }
    return '';
  }

  private getPeriodName(startPeriod: number): string {
    if (startPeriod >= 1 && startPeriod <= 4) {
      return '上午课程';
    } else if (startPeriod >= 5 && startPeriod <= 8) {
      return '下午课程';
    } else if (startPeriod >= 9 && startPeriod <= 10) {
      return '晚上课程';
    }
    return '课程';
  }

  private getSessionDescription(startPeriod: number, endPeriod: number): string {
    if (startPeriod === endPeriod) {
      return `第${startPeriod}节`;
    }
    return `第${startPeriod}节 - 第${endPeriod}节`;
  }
}