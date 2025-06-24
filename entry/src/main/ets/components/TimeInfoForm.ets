import { AddScheduleParams } from '../model/AddScheduleParams';
import { DayOption, DAY_OPTIONS } from '../model/AddCourseTypes';

@Component
export struct TimeInfoForm {
  @Link courseParams: AddScheduleParams;

  build() {
    Column({ space: 12 }) {
      Text('时间安排')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      
      // 星期选择
      this.buildDaySelection()
      
      // 开始节次
      this.buildPeriodInput('开始节次:', this.courseParams.startPeriod, (value: number) => {
        this.courseParams.startPeriod = value;
        if (this.courseParams.endPeriod < value) {
          this.courseParams.endPeriod = value;
        }
      })
      
      // 结束节次
      this.buildPeriodInput('结束节次:', this.courseParams.endPeriod, (value: number) => {
        if (value >= this.courseParams.startPeriod) {
          this.courseParams.endPeriod = value;
        }
      })
    }
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(8)
    .backgroundColor(Color.White)
  }

  @Builder
  buildDaySelection() {
    Column({ space: 8 }) {
      Text('星期:')
        .alignSelf(ItemAlign.Start)
        .fontSize(14)
      
      Column({ space: 8 }) {
        // 第一行：周一到周四
        Row({ space: 8 }) {
          ForEach(DAY_OPTIONS.slice(0, 4), (day: DayOption) => {
            this.buildDayButton(day)
          }, (day: DayOption) => day.value.toString())
        }
        .width('100%')
        
        // 第二行：周五到周日
        Row({ space: 8 }) {
          ForEach(DAY_OPTIONS.slice(4, 7), (day: DayOption) => {
            this.buildDayButton(day)
          }, (day: DayOption) => day.value.toString())
          
          Blank().layoutWeight(1)
        }
        .width('100%')
      }
    }
  }

  @Builder
  buildDayButton(day: DayOption) {
    Button(day.label)
      .fontSize(12)
      .height(36)
      .layoutWeight(1)
      .fontColor(this.courseParams.dayOfWeek === day.value ? Color.White : '#007DFF')
      .backgroundColor(this.courseParams.dayOfWeek === day.value ? '#007DFF' : Color.Transparent)
      .border({ width: 1, color: '#007DFF' })
      .borderRadius(4)
      .onClick(() => {
        this.courseParams.dayOfWeek = day.value;
      })
  }

  @Builder
  buildPeriodInput(label: string, value: number, onChange: (value: number) => void) {
    Row() {
      Text(label)
        .width(80)
      
      TextInput({ 
        placeholder: '1-10', 
        text: value.toString() 
      })
        .type(InputType.Number)
        .layoutWeight(1)
        .onChange((inputValue: string) => {
          const num = parseInt(inputValue);
          if (num >= 1 && num <= 10) {
            onChange(num);
          }
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}