import { AddScheduleParams } from '../model/AddScheduleParams';
import { COLOR_OPTIONS } from '../model/AddCourseTypes';
import { BreakpointSystem, DeviceType } from '../utils/BreakpointSystem';

@Component
export struct ColorSelectionForm {
  @Link courseParams: AddScheduleParams;
  @Prop breakpointSystem: BreakpointSystem;

  build() {
    Column({ space: 12 }) {
      Text('课程颜色')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)

      // 【修改】使用 Flex 实现颜色按钮的横向排列和自动换行
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center, alignContent: FlexAlign.Start }) {
        ForEach(COLOR_OPTIONS, (color: string) => {
          this.buildColorButton(color)
        }, (color: string) => color)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(8)
    .backgroundColor(Color.White)
  }

  @Builder
  buildColorButton(color: string) {
    Button()
      .width(44)
      .height(44)
      .margin({ right: 12, bottom: 12 })
      .borderRadius(22)
      .backgroundColor(color)
      .border({
        width: this.courseParams.color === color ? 3 : 1,
        color: this.courseParams.color === color ? '#333' : Color.Transparent
      })
      .onClick(() => {
        this.courseParams.color = color;
      })
  }
}