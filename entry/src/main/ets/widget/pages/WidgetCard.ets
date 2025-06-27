import { TodayCourseInfo } from '../../model/TodayScheduleVO'; // 导入我们定义的卡片数据模型

@Entry
@Component
struct WidgetCard {
  /*
   * The title.
   */
  readonly title: string = 'Hello World';
  /*
   * The action type.
   */
  readonly actionType: string = 'router';
  /*
   * The ability name.
   */
  readonly abilityName: string = 'EntryAbility';
  /*
   * The message.
   */
  readonly message: string = 'add detail';
  /*
   * The width percentage setting.
   */
  readonly fullWidthPercent: string = '100%';
  /*
   * The height percentage setting.
   */
  readonly fullHeightPercent: string = '100%';
  @State course: TodayCourseInfo = new TodayCourseInfo();

  // aboutToAppear生命周期钩子，在组件首次渲染前调用。
  aboutToAppear() {
    console.info('[CourseCard] 卡片即将显示，数据为:', JSON.stringify(this.course));
  }

  build() {
    FormLink({
      action: this.actionType,
      abilityName: this.abilityName,
      params: {
        message: this.message
      }
    }) {
      Column() {
        // 课程名称
        Text(this.course.name)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 8 })

        // 教师信息行
        Row() {
          Image($r('app.media.icon_teacher'))
            .width(28).height(28).margin({ right: 4 }).fillColor(Color.White)
          Text(this.course.teacher)
            .fontSize(14).fontColor(Color.White).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        //地点信息行
        Row() {
          Image($r('app.media.icon_location'))
            .width(28).height(28).margin({ right: 4 }).fillColor(Color.White)
          Text(this.course.location)
            .fontSize(14).fontColor(Color.White).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        //节次信息行
        Row() {
          Image($r('app.media.timeText'))
            .width(28).height(28).margin({ right: 4 }).fillColor(Color.White)
          Text(this.course.timeText)
            .fontSize(14).fontColor(Color.White).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        // 时间信息行
        Row() {
          Image($r('app.media.icon_time'))
            .width(28).height(28).margin({ right: 4 }).fillColor(Color.White)
          Text(this.course.timeText)
            .fontSize(14).fontColor(Color.White).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .padding(16)
      .justifyContent(FlexAlign.Center)
    }
  }

  //
  // 辅助函数：调整颜色亮度以创建渐变效果
  private adjustColorBrightness(hex: string, percent: number): string {
    if (!hex || typeof hex !== 'string') {
      return '#000000';
    }
    let h = hex.startsWith('#') ? hex.slice(1) : hex;
    if (h.length === 3) {
      h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
    }
    if (h.length !== 6) {
      return '#000000';
    }

    const num = parseInt(h, 16);
    let r = (num >> 16) + percent;
    r = Math.max(0, Math.min(255, r));
    let g = ((num >> 8) & 0x00FF) + percent;
    g = Math.max(0, Math.min(255, g));
    let b = (num & 0x0000FF) + percent;
    b = Math.max(0, Math.min(255, b));

    return `#${(r << 16 | g << 8 | b).toString(16).padStart(6, '0')}`;
  }
}



