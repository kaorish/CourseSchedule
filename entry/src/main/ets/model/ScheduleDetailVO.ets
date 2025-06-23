// src/main/ets/model/ScheduleDetailVO.ts

/**
 * 用于获取单个课程详情的视图对象
 */
export class ScheduleDetailVO {
  courseName: string = '';
  teacher: string = '';
  color: string = '';
  location: string = '';
  dayOfWeek: number = 0;
  startPeriod: number = 0;
  endPeriod: number = 0;
  weeks: number[] = [];
}