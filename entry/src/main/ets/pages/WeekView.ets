// src/main/ets/pages/WeekView.ets (最终正确版)

import { WeeklyCourseViewModel } from '../viewmodel/WeeklyCourseViewModel'
import { CourseInfo, WeekInfo, WeeklyCourseVO } from '../model/WeeklyCourseVO'
import { TimeSlot } from '../model/TimeSlot'
import display from '@ohos.display';

function getScreenWidthVp(): number {
  try { return px2vp(display.getDefaultDisplaySync().width); }
  catch (err) { return 360; }
}

@Component
export struct WeekView {
  @State private vm: WeeklyCourseViewModel = new WeeklyCourseViewModel();

  // ★★★ 核心修正 1：通过构造函数初始化 ★★★
  private week: number = 1;
  private currentSwiperWeek: number = 1;

  // ★★★ 核心修正 1：添加构造函数 ★★★
  constructor(options: { week: number, currentSwiperWeek: number }) {
    super()
    this.week = options.week;
    this.currentSwiperWeek = options.currentSwiperWeek;
  }

  private readonly courseCellHeight: number = 80;
  private readonly timeLeftWidth: number = 40;

  private timeSlots: TimeSlot[] = [
    new TimeSlot('1', '08:30', '09:15'), new TimeSlot('2', '09:20', '10:05'),
    new TimeSlot('3', '10:25', '11:10'), new TimeSlot('4', '11:15', '12:00'),
    new TimeSlot('5', '14:00', '14:45'), new TimeSlot('6', '14:50', '15:35'),
    new TimeSlot('7', '15:55', '16:40'), new TimeSlot('8', '16:45', '17:30'),
    new TimeSlot('9', '19:00', '19:45'), new TimeSlot('10', '19:50', '20:35')
  ];

  aboutToAppear() {
    this.vm.currentWeek = this.week;
    this.vm.semesterId = 1; // 假设学期ID为1
    this.vm.loadWeeklyCourses();
  }

  build() {
    Column() {
      // 只在当前需要显示的周渲染内容
      if (this.currentSwiperWeek === this.week) {
        if (this.vm.isLoading) {
          LoadingProgress().width(40).height(40).margin({ top: '40%' })
        } else if (this.vm.errorMessage) {
          Text(this.vm.errorMessage).fontColor(Color.Red).padding(20)
        } else if (this.vm.weeklyCourseData) {
          this.RealWeekView(this.vm.weeklyCourseData)
        } else {
          // 加载完成但无数据的情况
          Text(`第${this.week}周无课程安排`).fontColor(Color.Gray).margin({ top: '40%' })
        }
      }
    }
    .width('100%').height('100%').backgroundColor(Color.White)
  }

  @Builder
  RealWeekView(data: WeeklyCourseVO) {
    Stack({ alignContent: Alignment.TopStart }) {
      // --- 背景层 ---
      Row() {
        // 时间列
        Column() {
          ForEach(this.timeSlots, (slot: TimeSlot) => {
            Column() {
              Text(slot.label).fontSize(14).fontWeight(FontWeight.Bold)
              Text(slot.startTime).fontSize(10).fontColor(Color.Gray)
              Text(slot.endTime).fontSize(10).fontColor(Color.Gray)
            }.width(this.timeLeftWidth).height(this.courseCellHeight).justifyContent(FlexAlign.Center)
          }, (slot: TimeSlot) => slot.label)
        }
        // 网格线
        Column() {
          ForEach(this.timeSlots, () => {
            Divider().strokeWidth(0.5).color('#F0F0F0')
          })
        }.justifyContent(FlexAlign.SpaceAround).layoutWeight(1).height(this.timeSlots.length * this.courseCellHeight)
      }
      // ★★★ 核心修正 2：alignItems是修饰符 ★★★
      .alignItems(VerticalAlign.Top)
      .width('100%')

      // --- 课程卡片层 ---
      ForEach(data.courses, (course: CourseInfo) => {
        // ★★★ 核心修正 3：为@Builder调用包裹容器 ★★★
        Column() {
          this.CourseCard(course)
        }
        .width(`${(getScreenWidthVp() - this.timeLeftWidth) / 7 - 2}vp`)
        .height((course.endPeriod - course.startPeriod + 1) * this.courseCellHeight - 2)
        .position({
          x: `${this.timeLeftWidth + (course.dayOfWeek - 1) * ((getScreenWidthVp() - this.timeLeftWidth) / 7) + 1}vp`,
          y: `${(course.startPeriod - 1) * this.courseCellHeight + 1}vp`
        })
      }, (course: CourseInfo) => course.scheduleId.toString())
    }
    .height(this.timeSlots.length * this.courseCellHeight)
  }

  @Builder
  CourseCard(course: CourseInfo) {
    Column({ space: 4 }) {
      Text(course.name).fontSize(13).fontWeight(FontWeight.Bold).fontColor(Color.White)
        .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis }).textAlign(TextAlign.Center)
      Text(`${course.teacher}\n@${course.location}`)
        .fontSize(11).fontColor(Color.White).opacity(0.9).textAlign(TextAlign.Center)
    }
    .width('100%').height('100%').padding(6).borderRadius(8)
    .backgroundColor(course.color || '#007DFF').justifyContent(FlexAlign.Center)
  }
}