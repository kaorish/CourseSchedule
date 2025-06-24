// src/main/ets/model/TodayScheduleVO.ts
export class TodayCourseInfo {
  scheduleId: number = 0;
  name: string = '';
  teacher: string = '';
  location: string = '';
  color: string = '';
  startPeriod: number = 0;
  endPeriod: number = 0;
  timeText: string = ''; // e.g., "第1-2节"
}

export class TodayScheduleVO {
  date: string = ''; // e.g., "2025-06-24"
  dayName: string = ''; // e.g., "星期二"
  courses: TodayCourseInfo[] = [];
}