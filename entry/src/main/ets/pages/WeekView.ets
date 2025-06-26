// 文件路径: entry/src/main/ets/pages/WeekView.ets

import { WeeklyCourseViewModel } from '../viewmodel/WeeklyCourseViewModel'
import { CourseInfo, WeekInfo, WeeklyCourseVO } from '../model/WeeklyCourseVO'
import { TimeSlot } from '../model/TimeSlot'
import router from '@ohos.router'
import { AppSettings } from '../common/AppSettings';

@Component
export struct WeekView {
  @ObjectLink vm: WeeklyCourseViewModel;
  @Watch('onParamsChange')
  @Prop week: number;
  @Watch('onParamsChange')
  @StorageLink(AppSettings.CURRENT_SEMESTER_ID_KEY)
  private linkedSemesterId: number = 1;

  onParamsChange(): void {
    if (this.week === 0) {
      return;
    }
    this.vm.currentWeek = this.week;
    this.vm.loadWeeklyCourses();
  }

  aboutToAppear(): void {
    this.onParamsChange();
  }

  private shouldHideBottomBorder(courses: CourseInfo[], period: number, dayOfWeek: number): boolean {
    const courseStartingHere = this.getCoursesStartingAtSlot(courses, period, dayOfWeek)[0];
    if (courseStartingHere && courseStartingHere.endPeriod > courseStartingHere.startPeriod) {
      return true;
    }
    return false;
  }

  private readonly courseCellHeight: number = 80;
  private timeSlots: TimeSlot[] = [
    new TimeSlot('1', '08:30', '09:15'), new TimeSlot('2', '09:20', '10:05'),
    new TimeSlot('3', '10:25', '11:10'), new TimeSlot('4', '11:15', '12:00'),
    new TimeSlot('5', '14:00', '14:45'), new TimeSlot('6', '14:50', '15:35'),
    new TimeSlot('7', '15:55', '16:40'), new TimeSlot('8', '16:45', '17:30'),
    new TimeSlot('9', '19:00', '19:45'), new TimeSlot('10', '19:50', '20:35')
  ];

  build() {
    Stack() {
      Column() {
        if (this.vm.isLoading) {
          LoadingProgress().width(30).height(30).margin({ top: 100 })
        } else if (this.vm.errorMessage) {
          Text(this.vm.errorMessage).fontColor(Color.Red).padding(10).textAlign(TextAlign.Center)
        } else if (this.vm.weeklyCourseData) {
          this.RealWeekView(this.vm.weeklyCourseData)
        } else {
          Text(`第${this.week}周无课程`).fontColor(Color.Gray).margin({ top: 100 })
        }
      }.width('100%').height('100%').backgroundColor(Color.White).alignItems(HorizontalAlign.Center)

      this.FloatingAddButton()
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.BottomEnd)
  }

  @Builder
  FloatingAddButton() {
    Button() {
      Image($r('sys.media.ohos_ic_public_add'))
        .width(24)
        .height(24)
        .fillColor(Color.White)
    }
    .width(56)
    .height(56)
    .borderRadius(28)
    .backgroundColor('#007AFF')
    .margin({ right: 16, bottom: 16 })
    .shadow({
      radius: 8,
      color: 'rgba(0, 122, 255, 0.3)',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/AddCourse',
        params: {
          week: this.week,
          semesterId: this.linkedSemesterId,
          needRefresh: true
        }
      }).catch((err: Error) => {
        console.error('Navigation failed:', err);
      });
    })
    .position({ x: '100%', y: '100%' })
    .translate({ x: -72, y: -72 })
  }

  @Builder
  BreakDivider(label: string) {
    Row() {
      Divider().layoutWeight(1).strokeWidth(0.5).color('#E0E0E0')
      Text(label)
        .fontSize(12)
        .fontColor(Color.Gray)
        .padding({ left: 15, right: 15 })
        .layoutWeight(0)
      Divider().layoutWeight(1).strokeWidth(0.5).color('#E0E0E0')
    }
    .width('100%')
    .height(30)
    .backgroundColor('#F7F7F7')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  RealWeekView(data: WeeklyCourseVO) {
    Column() {
      Row() {
        Column().width(60)
        ForEach(data.weekInfo, (day: WeekInfo) => {
          Column({ space: 2 }) {
            Text(day.dayName).fontSize(14)
            Text(day.date).fontSize(10).fontColor(Color.Gray)
          }.layoutWeight(1).justifyContent(FlexAlign.Center)
        }, (day: WeekInfo) => day.dayOfWeek.toString())
      }
      .height(50)
      .padding({ left: 4, right: 4 })
      .backgroundColor(Color.White)
      .border({ width: { bottom: 1 }, color: '#E0E0E0' })

      Scroll() {
        Column({ space: 0 }) {
          ForEach(this.timeSlots, (slot: TimeSlot, timeIndex: number) => {
            if (timeIndex === 4) {
              this.BreakDivider('午休')
            } else if (timeIndex === 8) {
              this.BreakDivider('晚休')
            }
            Row({ space: 0 }) {
              // 【核心修正】为左侧时间列添加 padding，解决对齐问题
              Column() {
                Text(slot.label).fontSize(14).fontWeight(FontWeight.Bold)
                Text(slot.startTime).fontSize(10).fontColor(Color.Gray)
                Text(slot.endTime).fontSize(10).fontColor(Color.Gray)
              }
              .width(60)
              .height(this.courseCellHeight)
              .justifyContent(FlexAlign.Center)
              .padding({ top: 2, bottom: 2 }) // 添加与右侧单元格相同的垂直内边距
              .border({
                width: {
                  right: 0.5,
                  bottom: 0.5
                },
                color: '#E0E0E0'
              })

              ForEach(data.weekInfo, (day: WeekInfo) => {
                this.TimeSlotCell(data.courses, timeIndex + 1, day.dayOfWeek)
              }, (day: WeekInfo) => day.dayOfWeek.toString())
            }.width('100%').height(this.courseCellHeight)
          }, (slot: TimeSlot) => slot.label)
        }
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
  }

  @Builder
  TimeSlotCell(courses: CourseInfo[], period: number, dayOfWeek: number) {
    Stack() {
      Column()
        .width('100%')
        .height(this.courseCellHeight)
        .border({
          width: {
            right: 0.5,
            bottom: this.shouldHideBottomBorder(courses, period, dayOfWeek) ? 0 : 0.5
          },
          color: '#E0E0E0'
        })

      ForEach(this.getCoursesStartingAtSlot(courses, period, dayOfWeek), (course: CourseInfo) => {
        this.CourseCard(course)
      }, (course: CourseInfo) => course.scheduleId.toString())
    }
    .layoutWeight(1)
    .alignContent(Alignment.TopStart)
    .padding({
      top: 2,
      bottom: 2,
      left: 1,
      right: 1
    })
  }

  getCoursesStartingAtSlot(courses: CourseInfo[], period: number, dayOfWeek: number): CourseInfo[] {
    const filteredCourses = courses.filter((course: CourseInfo) => course.dayOfWeek === dayOfWeek && course.startPeriod === period);
    return filteredCourses;
  }

  calculateCourseHeight(course: CourseInfo): number {
    const spanPeriods = course.endPeriod - course.startPeriod + 1;
    const totalPadding = 4;
    return (spanPeriods * this.courseCellHeight) - totalPadding;
  }

  @Builder
  CourseCard(course: CourseInfo) {
    Column({ space: 4 }) {
      Text(course.name)
        .fontSize(14).fontWeight(FontWeight.Bold).fontColor(Color.White)
        .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
      Text(course.location ? `@${course.location}` : '')
        .fontSize(12).fontWeight(FontWeight.Bold).fontColor(Color.White)
        .maxLines(2)
        .textAlign(TextAlign.Center)
      Text(course.teacher || '')
        .fontSize(12).fontWeight(FontWeight.Bold).fontColor(Color.White)
        .maxLines(2)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(this.calculateCourseHeight(course))
    .padding(4)
    .borderRadius(6)
    .backgroundColor(course.color || '#007DFF')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}