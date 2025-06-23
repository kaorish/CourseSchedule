// src/main/ets/model/TimeSlot.ts (新建文件)
export class TimeSlot {
  label: string;
  startTime: string;
  endTime: string;

  constructor(label: string, startTime: string, endTime: string) {
    this.label = label;
    this.startTime = startTime;
    this.endTime = endTime;
  }
}