// 文件路径: entry/src/main/ets/widget/pages/WidgetCard.ets (最终修正版)
import { Want } from '@kit.AbilityKit';
import { TodayCourseResponse } from '../../viewmodel/TodayScheduleViewModel';

class WidgetData {
  todayText: string = '今天';
  weekText: string = '';
  courses: TodayCourseResponse[] = [];
  isLoading: boolean = true;
  message: string = '正在加载...';
}

@Entry
@Component
struct WidgetCard {
  // ★★★ 核心修正：添加 @State 装饰器，让UI能够响应数据变化 ★★★
  @State private data: WidgetData = new WidgetData();

  build() {
    FormLink({
      action: 'ability',
      bundleName: 'com.sunhao.myapplication', // 您的应用包名
      abilityName: 'EntryAbility'             // 您的主 Ability 名称
    }) {
      Column() {
        // 顶部信息栏
        Row() {
          Text(this.data.todayText)
            .fontSize(14)
            .fontColor('#333333')
          Blank()
          Text(this.data.weekText)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')
        .padding({ top: 12, left: 16, right: 16, bottom: 8 })

        // 中间内容区
        Column() {
          // isLoading为false且有课程时，将显示CourseList
          if (this.data.isLoading) {
            Text('正在加载...')
              .fontSize(16)
              .fontColor('#999999')
          } else if (this.data.courses && this.data.courses.length > 0) {
            this.CourseList(this.data.courses)
          } else {
            Text(this.data.message)
              .fontSize(16)
              .fontColor('#999999')
          }
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ left: 16, right: 16, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
      .borderRadius(24)
    }
  }

  // CourseList 和 CourseItem 构建器保持不变
  @Builder
  CourseList(courses: TodayCourseResponse[]) {
    List({ space: 8 }) {
      ForEach(courses, (course: TodayCourseResponse) => {
        ListItem() {
          this.CourseItem(course)
        }
      }, (course: TodayCourseResponse) => course.scheduleId.toString())
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CourseItem(course: TodayCourseResponse) {
    Row({ space: 8 }) {
      Divider().vertical(true).width(4).height(40).backgroundColor(course.color).borderRadius(2)
      Column({ space: 2 }) {
        Text(course.name)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .maxLines(1)
          .textOverflow({overflow: TextOverflow.Ellipsis})
        Text(`@ ${course.location}`)
          .fontSize(12)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({overflow: TextOverflow.Ellipsis})
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({left: 4})
      Column({ space: 4 }) {
        Text(course.specificStartTime ?? '')
          .fontSize(12)
          .fontColor('#333333')
        Text(course.specificEndTime ?? '')
          .fontSize(12)
          .fontColor('#333333')
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({left:8, right: 12, top: 10, bottom: 10})
    .borderRadius(12)
    .backgroundColor('#F7F7F7')
  }
}