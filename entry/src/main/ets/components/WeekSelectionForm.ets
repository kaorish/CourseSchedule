import { AddScheduleParams } from '../model/AddScheduleParams';

@Component
export struct WeekSelectionForm {
  @Link courseParams: AddScheduleParams;
  @Link selectedWeeks: Set<number>;
  private updateWeeksCallback: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      Text('上课周次')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      
      // 快速选择按钮
      this.buildQuickSelectButtons()
      
      // 周次选择网格
      this.buildWeekGrid()
      
      // 显示已选择的周次
      if (this.courseParams.weeks.length > 0) {
        Text(`已选择: ${this.courseParams.weeks.join('、')} 周`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ top: 8 })
          .alignSelf(ItemAlign.Start)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(8)
    .backgroundColor(Color.White)
  }

  @Builder
  buildQuickSelectButtons() {
    Row({ space: 8 }) {
      Button('全选')
        .fontSize(12)
        .height(32)
        .layoutWeight(1)
        .onClick(() => {
          for (let i = 1; i <= 20; i++) {
            this.selectedWeeks.add(i);
          }
          this.updateWeeksCallback();
        })
      
      Button('清空')
        .fontSize(12)
        .height(32)
        .layoutWeight(1)
        .onClick(() => {
          this.selectedWeeks.clear();
          this.updateWeeksCallback();
        })
      
      Button('单周')
        .fontSize(12)
        .height(32)
        .layoutWeight(1)
        .onClick(() => {
          this.selectedWeeks.clear();
          for (let i = 1; i <= 20; i += 2) {
            this.selectedWeeks.add(i);
          }
          this.updateWeeksCallback();
        })
      
      Button('双周')
        .fontSize(12)
        .height(32)
        .layoutWeight(1)
        .onClick(() => {
          this.selectedWeeks.clear();
          for (let i = 2; i <= 20; i += 2) {
            this.selectedWeeks.add(i);
          }
          this.updateWeeksCallback();
        })
    }
    .width('100%')
  }

  @Builder
  buildWeekGrid() {
    Grid() {
      ForEach(Array.from({ length: 20 }, (_: number, i: number) => i + 1), (week: number) => {
        GridItem() {
          Button(`${week}`)
            .width('100%')
            .height(44)
            .fontSize(14)
            .fontColor(this.selectedWeeks.has(week) ? Color.White : '#007DFF')
            .backgroundColor(this.selectedWeeks.has(week) ? '#007DFF' : Color.Transparent)
            .border({ width: 1, color: '#007DFF' })
            .borderRadius(6)
            .onClick(() => {
              if (this.selectedWeeks.has(week)) {
                this.selectedWeeks.delete(week);
              } else {
                this.selectedWeeks.add(week);
              }
              this.updateWeeksCallback();
            })
        }
        .padding(2)
      }, (week: number) => week.toString())
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
    .rowsGap(8)
    .columnsGap(8)
    .height(180)
    .width('100%')
  }

  aboutToAppear(): void {
    this.updateWeeksCallback = () => {
      this.courseParams.weeks = Array.from(this.selectedWeeks).sort((a: number, b: number) => a - b);
    };
  }
}