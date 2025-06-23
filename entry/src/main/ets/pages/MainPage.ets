// src/main/ets/pages/MainPage.ets (完整最终版)

import { WeeklyCourseViewModel } from '../viewmodel/WeeklyCourseViewModel';
import { Index } from './Index' // 导入周视图页面

@Entry
@Component
struct MainPage {
  @State currentTabIndex: number = 1; // 默认选中中间的“课程表”Tab
  private controller: TabsController = new TabsController();

  // ★★★ 核心：在最顶层提供currentWeek状态 ★★★
  @Provide('currentWeek') currentWeek: number = 15; // 默认第15周

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
      // --- Tab 1: 今日课程 ---
      TabContent() {
        // 你未来创建的“今日课程”页面
        Column(){
          Text("今日课程页面")
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)

      }
      .tabBar(this.TabBuilder('今日', 0, '📚'))

      // --- Tab 2: 课程表 (我们的Index页面) ---
      TabContent() {
        // 将Index组件作为Tab的内容
        Index()
      }
      .tabBar(this.TabBuilder('课程表', 1, '📅'))

      // --- Tab 3: 设置 ---
      TabContent() {
        // 你未来创建的“设置”页面
        Column(){
          Text("设置页面")
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      }
      .tabBar(this.TabBuilder('我的', 2, '⚙️'))
    }
    .onChange((index: number) => {
      this.currentTabIndex = index;
    })
    .barWidth('100%')
    .barHeight(60)
    .backgroundColor('#F1F3F5')
    .animationDuration(200)
  }

  // 自定义TabBar的构建器
  @Builder
  TabBuilder(title: string, index: number, icon: string) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(24)
      Text(title)
        .fontSize(12)
        .fontColor(this.currentTabIndex === index ? '#007DFF' : '#666666')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}