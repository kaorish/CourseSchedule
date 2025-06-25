export class ScheduleManageVO {
  scheduleId: number = 0
  courseName: string = ''
  teacher: string = ''
  location: string = ''
  dayOfWeekText: string = ''
  timeText: string = ''
  weeksText: string = ''
  color: string = ''
}

export class ScheduleDetailVO {
  courseName: string = ''
  teacher: string = ''
  color: string = ''
  location: string = ''
  dayOfWeek: number = 0
  startPeriod: number = 0
  endPeriod: number = 0
  weeks: number[] = []
}

export class UpdateScheduleParams {
  courseName: string = ''
  teacher: string = ''
  color: string = ''
  location: string = ''
  dayOfWeek: number = 0
  startPeriod: number = 0
  endPeriod: number = 0
  weeks: number[] = []
}

export class GetScheduleListParams {
  semesterId: number | undefined = 0
}