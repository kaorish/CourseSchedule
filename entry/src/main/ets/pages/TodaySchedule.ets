// src/main/ets/pages/TodaySchedule.ets (重构后使用ViewModel并支持滚动)

import { TodayScheduleViewModel, DailyCourseTimeSlot, CourseTimeSegment, TodayCourseResponse } from '../viewmodel/TodayScheduleViewModel';
import router from '@ohos.router'; // 导入路由模块

@Component // 标识该类是一个ArkUI组件
export struct TodaySchedule { // 定义 TodaySchedule 组件
  // ★★★ 核心修正点：通过@Consume注入ViewModel实例 ★★★
  // 'todayScheduleVM' 是MainPage中@Provide的变量名
  @Consume('todayScheduleVM') private vm: TodayScheduleViewModel;

  aboutToAppear() { // 组件生命周期函数：即将显示
    // ViewModel的日期初始化已在构造函数中完成
    this.vm.loadTodayCourses(); // 调用ViewModel的加载今日课程方法
  }

  /**
   * @description 构建页面的头部区域。
   */
  @Builder // 标识该方法为UI构建器
  Header() { // 定义头部区域的构建方法
    Column() { // 使用列布局
      Text(`${this.vm.todayDate} ${this.vm.todayWeekday}`) // 显示日期和星期，从ViewModel获取
        .fontSize(16) // 设置字体大小
        .fontColor(Color.White) // 设置字体颜色为白色
        .opacity(0.9) // 设置透明度
        .margin({ top: 20 }) // 设置上外边距

      Text('朕还能学') // 显示标题文本
        .fontSize(30) // 设置字体大小
        .fontWeight(FontWeight.Bold) // 设置字体粗细为粗体
        .fontColor(Color.White) // 设置字体颜色为白色
        .margin({ top: 8 }) // 设置上外边距
    }
    .width('100%') // 设置宽度为100%
    .height(180) // 设置固定高度
    .backgroundColor('#007AFF') // 设置背景颜色
    .alignItems(HorizontalAlign.Start) // 设置水平对齐方式为开始
    .padding({ left: 24 }) // 设置左内边距
  }

  /**
   * @description 构建单个课程区域（上午、下午或晚上）。
   * @param {DailyCourseTimeSlot} slot - 时间段数据。
   */
  @Builder
  CourseSection(slot: DailyCourseTimeSlot) {
    Column() {
      Text(slot.period)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.Black)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })

      // 遍历该时间段内的所有具体时间段
      ForEach(slot.segments, (segment: CourseTimeSegment) => {
        Row() {
          Column() {
            Text(segment.startTime)
              .fontSize(14)
              .fontColor('#666')
            Blank()
            Text(segment.endTime)
              .fontSize(14)
              .fontColor('#666')
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(HorizontalAlign.Center)

          Divider()
            .vertical(true)
            .height(50)
            .backgroundColor('#007AFF')
            .strokeWidth(2)
            .margin({ left: 16, right: 16 })

          Column() {
            if (segment.courses.length === 0) {
              Text('空闲')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333')
                .margin({ top: 1 })
            } else {
              Column({ space: 8 }) {
                ForEach(segment.courses, (course: TodayCourseResponse) => {
                  Column() {
                    Text(course.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Color.Black)
                    Text(`@${course.location}`)
                      .fontSize(14)
                      .fontColor('#666')
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                }, (course: TodayCourseResponse) => course.scheduleId.toString())
              }.alignItems(HorizontalAlign.Start)
            }

            Text(segment.session)
              .fontSize(14)
              .fontColor('#999')
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: segment === slot.segments[slot.segments.length - 1] ? 0 : 16 }) // 最后一个段落不加底部间距
      }, (segment: CourseTimeSegment) => `${segment.startTime}-${segment.endTime}`)
    }
    .width('100%') // 设置宽度为100%
    .padding({ top: 24, bottom: 24 }) // 设置上下内边距
  }

  build() { // 组件的构建方法
    Column() { // 使用列布局作为根容器
      // 顶部导航栏
      // Row() {
      //   Text('今日课程')
      //     .fontSize(20)
      //     .fontColor(Color.White)
      //     .fontWeight(FontWeight.Bold)
      //     .margin({ left: 140 })
      //   Blank()
      // }
      // .width('100%')
      // .height(50)
      // .padding({ left: 16, right: 16 })
      // .backgroundColor('#007AFF') // 设置背景颜色
      // 使用Stack组件让内容卡片可以覆盖在头部之上
      Stack({ alignContent: Alignment.Top }) { // 使用堆叠布局，内容顶部对齐
        // 蓝色头部
        this.Header() // 调用头部构建器

        // ★★★ 核心修正点：将白色内容卡片包裹在Scroll中 ★★★
        Scroll() {
          Column() { // 白色内容卡片的列布局
            // 显示加载状态或错误信息
            if (this.vm.isLoading) {
              LoadingProgress().width(30).height(30).margin({ top: 100 });
            } else if (this.vm.errorMessage) {
              Text(this.vm.errorMessage)
                .fontColor(Color.Red)
                .fontSize(16)
                .margin({ top: 50 });
            } else if (this.vm.dailySchedule.length > 0) {
              ForEach(this.vm.dailySchedule, (slot: DailyCourseTimeSlot) => { // 遍历每日课程安排，从ViewModel获取
                this.CourseSection(slot); // 调用课程区域构建器
                // 在区域之间添加分割线，但最后一个区域后不添加
                if (this.vm.dailySchedule.indexOf(slot) < this.vm.dailySchedule.length - 1) { // 如果不是最后一个课程段
                  Divider().width('90%').strokeWidth(0.5).color('#E0E0E0').margin({ top: 30 }); // 添加分割线
                }
              });
            } else {
              Text('今日无课程安排')
                .fontColor(Color.Gray)
                .fontSize(16)
                .margin({ top: 50 });
            }
          }
          .width('100%') // 设置宽度为100%
          .padding({ left: 24, right: 24 }) // 设置左右内边距
          .backgroundColor(Color.White) // 设置背景颜色为白色
          .borderRadius({ topLeft: 20, topRight: 20 }) // 设置左上和右上的圆角半径
          .margin({ top: 90 }) // 将卡片向下推移以覆盖部分头部，设置上外边距
        }
        .scrollable(ScrollDirection.Vertical) // 允许垂直滚动
        .layoutWeight(1) // 确保Scroll组件占据可用空间
      }
      .layoutWeight(1) // 设置布局权重，使其占据剩余空间
    }
    .width('100%') // 设置宽度为100%
    .height('100%') // 设置高度为100%
    .backgroundColor('#F5F5F5'); // 整个页面的浅灰色背景
  }
}
