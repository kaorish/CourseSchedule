import { WeeklyCourseViewModel } from '../viewmodel/WeeklyCourseViewModel'
import { CourseInfo, WeekInfo, WeeklyCourseVO } from '../model/WeeklyCourseVO'
import { TimeSlot } from '../model/TimeSlot'
import router from '@ohos.router'
import { AppSettings } from '../common/AppSettings'; // ★★★ 1. 导入 AppSettings


@Component
export struct WeekView {
  @ObjectLink vm: WeeklyCourseViewModel;
  private week: number = 0;
  @State refreshFlag: number = 0;

  private readonly courseCellHeight: number = 80;
  private timeSlots: TimeSlot[] = [
    new TimeSlot('1', '08:30', '09:15'), new TimeSlot('2', '09:20', '10:05'),
    new TimeSlot('3', '10:25', '11:10'), new TimeSlot('4', '11:15', '12:00'),
    new TimeSlot('5', '14:00', '14:45'), new TimeSlot('6', '14:50', '15:35'),
    new TimeSlot('7', '15:55', '16:40'), new TimeSlot('8', '16:45', '17:30'),
    new TimeSlot('9', '19:00', '19:45'), new TimeSlot('10', '19:50', '20:35')
  ];

  aboutToAppear(): void {
    if (!this.vm.weeklyCourseData && this.week > 0) {
      this.vm.currentWeek = this.week;
      this.vm.loadWeeklyCourses();
    }

    const params = router.getParams() as Record<string, Object>;
    if (params && params['shouldRefresh']) {
      this.vm.loadWeeklyCourses();
    }
  }

  onPageShow(): void {
    console.log('WeekView页面显示，刷新数据');
    this.forceRefresh();
  }

  private forceRefresh() {
    this.refreshFlag++;
    this.vm.loadWeeklyCourses();
  }

  // FloatingAddButton 方法是我们需要修改的地方
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
      // ★★★ 3. 在跳转前，从 AppStorage 获取当前学期 ID ★★★
      const currentSemesterId = AppStorage.Get<number>(AppSettings.CURRENT_SEMESTER_ID_KEY);

      router.pushUrl({
        url: 'pages/AddCourse',
        params: {
          week: this.week,
          semesterId: currentSemesterId, // ★★★ 4. 使用从 AppStorage 获取的 ID ★★★
          needRefresh: true
        }
      }).catch((err: Error) => {
        console.error('Navigation failed:', err);
      });
    })
    .position({ x: '100%', y: '100%' })
    .translate({ x: -72, y: -72 })
  }

  // build 及其他所有 @Builder 方法和函数保持不变
  build() {
    Stack() {
      Column() {
        Text(`${this.refreshFlag}`).width(0).height(0).opacity(0)

        if (this.vm.isLoading) {
          LoadingProgress().width(30).height(30).margin({ top: 100 })
        } else if (this.vm.errorMessage) {
          Text(this.vm.errorMessage).fontColor(Color.Red)
        } else if (this.vm.weeklyCourseData) {
          this.RealWeekView(this.vm.weeklyCourseData)
        } else {
          Text(`第${this.week}周无课程`).fontColor(Color.Gray)
        }
      }.width('100%').height('100%').backgroundColor(Color.White)

      this.FloatingAddButton()
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.BottomEnd)
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
      }.height(50).padding({ left: 4, right: 4 }).backgroundColor('#F8F8F8')

      Scroll() {
        Column({ space: 0 }) {
          ForEach(this.timeSlots, (slot: TimeSlot, timeIndex: number) => {
            Row({ space: 0 }) {
              Column() {
                Text(slot.label).fontSize(14).fontWeight(FontWeight.Bold)
                Text(slot.startTime).fontSize(10).fontColor(Color.Gray)
                Text(slot.endTime).fontSize(10).fontColor(Color.Gray)
              }
              .width(60)
              .height(this.courseCellHeight)
              .justifyContent(FlexAlign.Center)
              .border({ width: 0.5, color: '#F0F0F0' })

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
        .border({ width: 0.5, color: '#F0F0F0' })

      ForEach(this.getCoursesStartingAtSlot(courses, period, dayOfWeek), (course: CourseInfo) => {
        this.CourseCard(course)
      }, (course: CourseInfo) => course.scheduleId.toString())
    }
    .layoutWeight(1)
    .alignContent(Alignment.TopStart)
  }

  getCoursesStartingAtSlot(courses: CourseInfo[], period: number, dayOfWeek: number): CourseInfo[] {
    console.log(`查找课程: period=${period}, dayOfWeek=${dayOfWeek}`);
    const filteredCourses = courses.filter((course: CourseInfo) => {
      const match = course.dayOfWeek === dayOfWeek && course.startPeriod === period;
      if (match) {
        console.log(`找到课程: ${course.name}, 周${course.dayOfWeek}, 第${course.startPeriod}-${course.endPeriod}节`);
      }
      return match;
    });
    return filteredCourses;
  }

  calculateCourseHeight(course: CourseInfo): number {
    const spanPeriods = course.endPeriod - course.startPeriod + 1;
    return spanPeriods * this.courseCellHeight;
  }

  @Builder
  CourseCard(course: CourseInfo) {
    Column({ space: 2 }) {
      Text(course.name)
        .fontSize(14).fontWeight(FontWeight.Bold).fontColor(Color.White)
        .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(course.location ? `@${course.location}` : '')
        .fontSize(12).fontWeight(FontWeight.Bold).fontColor(Color.White)
        .maxLines(2)
      Text(course.teacher || '')
        .fontSize(12).fontWeight(FontWeight.Bold).fontColor(Color.White)
        .maxLines(2)
    }
    .width('calc(100% - 2vp)')
    .height(this.calculateCourseHeight(course) - 2)
    .padding(4)
    .margin(1)
    .borderRadius(4)
    .backgroundColor(course.color || '#007DFF')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
  }
}