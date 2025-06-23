// src/main/ets/model/ScheduleAddDTO.ts

/**
 * 添加新课程时向后端发送的数据传输对象 (DTO)
 */
export class ScheduleAddDTO {
  semesterId: number = 0;
  courseName: string = '';
  teacher: string = '';
  color: string = '#007DFF'; // 默认一个颜色
  location: string = '';
  dayOfWeek: number = 1; // 默认周一
  startPeriod: number = 1;
  endPeriod: number = 1;
  weeks: number[] = [];
}