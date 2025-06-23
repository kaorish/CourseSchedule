// src/main/ets/model/WeeklyCourseVO.ts
export class WeekInfo {
  dayOfWeek: number = 0;
  date: string = '';
  dayName: string = '';
}

export class CourseInfo {
  scheduleId: number = 0;
  name: string = '';
  teacher: string = '';
  location: string = '';
  color: string = '';
  dayOfWeek: number = 0;
  startPeriod: number = 0;
  endPeriod: number = 0;
}

export class WeeklyCourseVO {
  weekNumber: number = 0;
  weekInfo: WeekInfo[] = [];
  courses: CourseInfo[] = [];
}