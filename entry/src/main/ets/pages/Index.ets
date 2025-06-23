// src/main/ets/pages/Index.ets (最终正确版)

import { WeekView } from './WeekView'

@Component
export struct Index {
  @State currentWeek: number = 15;

  private swiperController: SwiperController = new SwiperController();
  private readonly totalWeeks: number = 20;
  private readonly startWeek: number = 1;
  private weekNumbers: number[] = [];

  aboutToAppear() {
    if (this.weekNumbers.length === 0) {
      for (let i = this.startWeek; i <= this.totalWeeks; i++) {
        this.weekNumbers.push(i);
      }
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('<').fontSize(20).fontWeight(FontWeight.Bold).width(40).height(40).textAlign(TextAlign.Center)
          .onClick(() => { if (this.currentWeek > this.startWeek) this.swiperController.showPrevious() })
          .opacity(this.currentWeek > this.startWeek ? 1 : 0.3)

        Text(`第${this.currentWeek}周`).layoutWeight(1).textAlign(TextAlign.Center).fontSize(18).fontWeight(FontWeight.Medium)

        Text('⇌').fontSize(20).fontWeight(FontWeight.Bold).width(40).height(40).textAlign(TextAlign.Center)
          .onClick(() => { /* 弹出周数选择 */ })
      }
      .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White)

      // Swiper容器
      Swiper(this.swiperController) {
        ForEach(this.weekNumbers, (week: number) => {
          // ★★★ 在这里创建WeekView，并通过构造函数传递必要的参数 ★★★
          WeekView({ week: week, currentSwiperWeek: this.currentWeek })
        }, (week: number) => week.toString())
      }
      .index(this.currentWeek - this.startWeek)
      .indicator(false)
      .loop(false)
      .cachedCount(2) // 开启预加载
      .onChange((index: number) => {
        this.currentWeek = index + this.startWeek;
      })
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}