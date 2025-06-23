// src/main/ets/model/ScheduleManageVO.ts

/**
 * 用于“课程管理”页面的列表项视图对象
 */
export class ScheduleManageVO {
  scheduleId: number = 0;
  courseName: string = '';
  teacher: string = '';
  location: string = '';
  // 后端转换好的星期文本，如 "周一"
  dayOfWeekText: string = '';
  // 后端转换好的时间文本，如 "第1-2节"
  timeText: string = '';
  // 后端转换好的周次文本，如 "1-16周"
  weeksText: string = '';
  color: string = '';
}