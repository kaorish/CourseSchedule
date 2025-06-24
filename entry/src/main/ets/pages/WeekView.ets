// src/main/ets/pages/WeekView.ets (Flex布局版本)

import { WeeklyCourseViewModel } from '../viewmodel/WeeklyCourseViewModel'
import { CourseInfo, WeekInfo, WeeklyCourseVO } from '../model/WeeklyCourseVO'
import { TimeSlot } from '../model/TimeSlot'
import router from '@ohos.router' // 添加路由导入

@Component
export struct WeekView {
  @ObjectLink vm: WeeklyCourseViewModel;
  private week: number = 0;
  @State refreshFlag: number = 0; // 添加刷新标志

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
    
    // 监听页面返回参数，判断是否需要刷新
    const params = router.getParams() as Record<string, Object>;
    if (params && params['shouldRefresh']) {
      this.vm.loadWeeklyCourses();
    }
  }

  // 添加页面显示时的刷新逻辑
  onPageShow(): void {
    console.log('WeekView页面显示，刷新数据');
    this.forceRefresh();
  }

  // 强制刷新方法
  private forceRefresh() {
    this.refreshFlag++;
    this.vm.loadWeeklyCourses();
  }

  build() {
    Stack() { // 使用Stack来叠加悬浮按钮
      Column() {
        // 添加隐藏的刷新标志文本，触发UI更新
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

      // 悬浮添加按钮
      this.FloatingAddButton()
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.BottomEnd)
  }

  // 悬浮添加按钮
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
      // 跳转到添加课程页面，传递当前周数和刷新回调
      router.pushUrl({
        url: 'pages/AddCourse',
        params: {
          week: this.week,
          semesterId: this.vm.semesterId,
          // 传递一个标识，让AddCourse页面知道需要通知刷新
          needRefresh: true
        }
      }).then(() => {
        console.log('成功跳转到添加课程页面');
      }).catch((err: Error) => {
        console.error('Navigation failed:', err);
        // 显示错误提示
        AlertDialog.show({
          title: '跳转失败',
          message: `无法打开添加课程页面: ${err.message}`,
          confirm: {
            value: '确定',
            action: () => {
              console.log('用户确认错误提示');
            }
          }
        });
      });
    })
    .position({ x: '100%', y: '100%' })
    .translate({ x: -72, y: -72 }) // 向左上偏移，留出边距
  }

  // ★★★ 使用传统的行列布局方式 ★★★
  @Builder
  RealWeekView(data: WeeklyCourseVO) {
    Column() {
      // 星期表头
      Row() {
        Column().width(60) // 左侧时间列宽度
        ForEach(data.weekInfo, (day: WeekInfo) => {
          Column({ space: 2 }) {
            Text(day.dayName).fontSize(14)
            Text(day.date).fontSize(10).fontColor(Color.Gray)
          }.layoutWeight(1).justifyContent(FlexAlign.Center)
        }, (day: WeekInfo) => day.dayOfWeek.toString())
      }.height(50).padding({ left: 4, right: 4 }).backgroundColor('#F8F8F8')

      // ★★★ 修复：统一的课程表主体，优化滚动显示 ★★★
      Scroll() {
        Column({ space: 0 }) {
          ForEach(this.timeSlots, (slot: TimeSlot, timeIndex: number) => {
            Row({ space: 0 }) {
              // 左侧时间信息
              Column() {
                Text(slot.label).fontSize(14).fontWeight(FontWeight.Bold)
                Text(slot.startTime).fontSize(10).fontColor(Color.Gray)
                Text(slot.endTime).fontSize(10).fontColor(Color.Gray)
              }
              .width(60)
              .height(this.courseCellHeight)
              .justifyContent(FlexAlign.Center)
              .border({ width: 0.5, color: '#F0F0F0' })

              // ★★★ 修复：课程格子行 - 使用正确的映射 ★★★
              ForEach(data.weekInfo, (day: WeekInfo) => {
                this.TimeSlotCell(data.courses, timeIndex + 1, day.dayOfWeek)
              }, (day: WeekInfo) => day.dayOfWeek.toString())
            }.width('100%').height(this.courseCellHeight)
          }, (slot: TimeSlot) => slot.label)
        }
      }
      .scrollable(ScrollDirection.Vertical)  // 确保垂直方向可滚动
      .scrollBar(BarState.Auto)              // 自动显示滚动条
      .edgeEffect(EdgeEffect.Spring)         // 添加滚动边缘效果
      .layoutWeight(1)                       // 让滚动区域占据剩余的所有空间
    }
  }

  // ★★★ 修复 TimeSlotCell 方法 ★★★
  @Builder
  TimeSlotCell(courses: CourseInfo[], period: number, dayOfWeek: number) {
    Stack() {
      // 背景格子
      Column()
        .width('100%')
        .height(this.courseCellHeight)
        .border({ width: 0.5, color: '#F0F0F0' })

      // ★★★ 修复：只在课程开始节次显示课程卡片 ★★★
      ForEach(this.getCoursesStartingAtSlot(courses, period, dayOfWeek), (course: CourseInfo) => {
        this.CourseCard(course)
      }, (course: CourseInfo) => course.scheduleId.toString())
    }
    .layoutWeight(1)
    .alignContent(Alignment.TopStart)
  }

  // ★★★ 修复：获取在指定时间段开始的课程 ★★★
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

  // ★★★ 添加：计算课程卡片高度 ★★★
  calculateCourseHeight(course: CourseInfo): number {
    const spanPeriods = course.endPeriod - course.startPeriod + 1;
    return spanPeriods * this.courseCellHeight;
  }

  // ★★★ 修复：课程卡片 ★★★
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