// src/main/ets/model/ScheduleUpdateDTO.ts

/**
 * 更新课程时向后端发送的数据传输对象 (DTO)
 */
export class ScheduleUpdateDTO {
  courseName: string = '';
  teacher: string = '';
  color: string = '';
  location: string = '';
  dayOfWeek: number = 0;
  startPeriod: number = 0;
  endPeriod: number = 0;
  weeks: number[] = [];
}