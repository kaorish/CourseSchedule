import { AddScheduleParams } from '../model/AddScheduleParams';
import { COLOR_OPTIONS } from '../model/AddCourseTypes';

@Component
export struct ColorSelectionForm {
  @Link courseParams: AddScheduleParams;

  build() {
    Column({ space: 12 }) {
      Text('课程颜色')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      
      Column({ space: 12 }) {
        // 第一行颜色
        Row({ space: 12 }) {
          ForEach(COLOR_OPTIONS.slice(0, 4), (color: string) => {
            this.buildColorButton(color)
          }, (color: string) => color)
        }
        .justifyContent(FlexAlign.SpaceEvenly)
        .width('100%')
        
        // 第二行颜色
        Row({ space: 12 }) {
          ForEach(COLOR_OPTIONS.slice(4, 8), (color: string) => {
            this.buildColorButton(color)
          }, (color: string) => color)
        }
        .justifyContent(FlexAlign.SpaceEvenly)
        .width('100%')
      }
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