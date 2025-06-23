// src/main/ets/model/SemesterUpdateDTO.ts

/**
 * 更新学期信息时向后端发送的数据传输对象 (DTO)
 */
export class SemesterUpdateDTO {
  startDate: string = ''; // 格式 "YYYY-MM-DD"
  totalWeeks: number = 0;
}