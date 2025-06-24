export class AddScheduleParams {
  semesterId: number = 0;
  courseName: string = '';
  teacher: string = '';
  color: string = '#007DFF';
  location: string = '';
  dayOfWeek: number = 1;
  startPeriod: number = 1;
  endPeriod: number = 1;
  weeks: number[] = [];
}