// 文件路径: entry/src/main/ets/pages/WeekView.ets

import { WeeklyCourseViewModel } from '../viewmodel/WeeklyCourseViewModel'
import { CourseInfo, WeekInfo, WeeklyCourseVO } from '../model/WeeklyCourseVO'
import { TimeSlot } from '../model/TimeSlot'
import router from '@ohos.router'
import { AppSettings } from '../common/AppSettings';

@Component
export struct WeekView {
  @ObjectLink vm: WeeklyCourseViewModel;

  // --- 修正1: 为 week 添加 @Prop 装饰器 ---
  // @Watch 必须与状态装饰器配对。@Prop表示该变量由父组件单向传入。
  @Watch('onParamsChange')
  @Prop
  week: number;

  // --- 修正2: @Watch 和 @StorageLink 的组合是正确的，保持不变 ---
  @Watch('onParamsChange')
  @StorageLink(AppSettings.CURRENT_SEMESTER_ID_KEY)
  private linkedSemesterId: number = 1;

  // 统一的响应方法，当 week 或 linkedSemesterId 变化时触发
  onParamsChange(): void {
    // 初始创建时 week 可能为0，避免无效加载
    if (this.week === 0) {
      return;
    }
    // 同步周数到ViewModel
    this.vm.currentWeek = this.week;
    console.log(`[WeekView] Params changed. Week: ${this.vm.currentWeek}, SemesterID: ${this.linkedSemesterId}. Triggering data load.`);
    // 命令ViewModel加载数据
    this.vm.loadWeeklyCourses();
  }

  // aboutToAppear 负责首次加载
  aboutToAppear(): void {
    console.log('[WeekView] aboutToAppear: Triggering initial load.');
    this.onParamsChange();
  }

  // --- 修正3: 'refreshFlag' 和 'forceRefresh' 已被移除 ---

  private readonly courseCellHeight: number = 80;
  private timeSlots: TimeSlot[] = [
    new TimeSlot('1', '08:30', '09:15'), new TimeSlot('2', '09:20', '10:05'),
    new TimeSlot('3', '10:25', '11:10'), new TimeSlot('4', '11:15', '12:00'),
    new TimeSlot('5', '14:00', '14:45'), new TimeSlot('6', '14:50', '15:35'),
    new TimeSlot('7', '15:55', '16:40'), new TimeSlot('8', '16:45', '17:30'),
    new TimeSlot('9', '19:00', '19:45'), new TimeSlot('10', '19:50', '20:35')
  ];

  // build 方法中移除了对 refreshFlag 的引用
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
      // 此处逻辑保持不变
      router.pushUrl({
        url: 'pages/AddCourse',
        params: {
          week: this.week,
          semesterId: this.linkedSemesterId, // 直接使用绑定的学期ID
          needRefresh: true
        }
      }).catch((err: Error) => {
        console.error('Navigation failed:', err);
      });
    })
    .position({ x: '100%', y: '100%' })
    .translate({ x: -72, y: -72 })
  }

  // 其余所有 @Builder 方法 (RealWeekView, TimeSlotCell, CourseCard 等) 保持原样即可
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
    const filteredCourses = courses.filter((course: CourseInfo) => course.dayOfWeek === dayOfWeek && course.startPeriod === period);
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