// src/main/ets/pages/Index.ets (最终Swiper版)

import { WeeklyCourseViewModel } from '../viewmodel/WeeklyCourseViewModel'
import { WeekView } from './WeekView' // 导入我们新建的WeekView组件
import router from '@ohos.router'
import { AppSettings } from '../common/AppSettings';

// 定义一个类型来持有每个页面的ViewModel
type WeekViewModelMap = Map<number, WeeklyCourseViewModel>;

@Component
export struct Index {
  // ★★★ 核心：用一个Map来存储每一周对应的ViewModel ★★★
  @State weekViewModels: WeekViewModelMap = new Map();

  // ★★★ 核心修正 #1: 使用 @StorageLink 响应式地绑定当前周 ★★★
  // 这将自动从 AppStorage 获取值，并在值从其他地方（如MainPage）被修改时，自动更新本页面的 currentWeek
  @StorageLink(AppSettings.CALCULATED_CURRENT_WEEK_KEY)
  @Watch('onCurrentWeekChange') // 添加 Watch 回调，当 currentWeek 变化时触发
  private currentWeek: number = 1; // 提供一个默认值，以防AppStorage中无值

  // 添加周数选择对话框的状态
  @State showWeekPicker: boolean = false;

  private swiperController: SwiperController = new SwiperController();
  private readonly totalWeeks: number = 20;
  private readonly startWeek: number = 1;
  private weekNumbers: number[] = [];

  // ★★★ 核心修正 #2: 定义 Watch 回调函数 ★★★
  // 当 currentWeek (从 AppStorage 同步而来) 发生变化时，命令式地跳转 Swiper
  onCurrentWeekChange(): void {
    const targetIndex = this.currentWeek - this.startWeek;
    // 确保 index 在有效范围内
    if (targetIndex >= 0 && targetIndex < this.totalWeeks) {
      console.log(`[Index.ets] currentWeek changed to ${this.currentWeek}. Jumping Swiper to index: ${targetIndex}`);
      // 使用 controller 命令式地跳转 Swiper，这比声明式绑定更可靠
      // 第二个参数 false 表示跳转时无动画，避免用户看到闪烁
      this.swiperController.changeIndex(targetIndex, false);
    }
  }

  aboutToAppear() {
    if (this.weekNumbers.length === 0) {
      for (let i = this.startWeek; i <= this.totalWeeks; i++) {
        this.weekNumbers.push(i);
      }
    }
    // 确保当前周的ViewModel已创建
    this.getOrCreateViewModelForWeek(this.currentWeek);

    // ★★★ 核心修正 #3: 手动调用一次 ★★★
    // 确保即使@Watch不触发初始值的变更，也能在页面出现时跳转到正确的周
    this.onCurrentWeekChange();
  }

  // 获取或创建指定周的ViewModel
  getOrCreateViewModelForWeek(week: number): WeeklyCourseViewModel {
    if (!this.weekViewModels.has(week)) {
      this.weekViewModels.set(week, new WeeklyCourseViewModel());
    }
    return this.weekViewModels.get(week)!;
  }

  goToPreviousWeek(): void { if (this.currentWeek > this.startWeek) this.swiperController.showPrevious(); }
  goToNextWeek(): void { if (this.currentWeek < this.totalWeeks) this.swiperController.showNext(); }

  // 添加跳转到指定周的方法
  jumpToWeek(targetWeek: number): void {
    if (targetWeek >= this.startWeek && targetWeek <= this.totalWeeks) {
      // 先更新currentWeek状态
      this.currentWeek = targetWeek;
      // 确保目标周的ViewModel已创建
      this.getOrCreateViewModelForWeek(targetWeek);

      // 使用changeIndex方法跳转到指定页面
      const targetIndex = targetWeek - this.startWeek;
      this.swiperController.changeIndex(targetIndex);
    }
  }

  // 打开周数选择器
  openWeekPicker(): void {
    this.showWeekPicker = true;
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TopNavBar()

      // 主内容区：Swiper
      Swiper(this.swiperController) {
        ForEach(this.weekNumbers, (week: number) => {
          // ★★★ 为每个Swiper页面传入它自己的ViewModel ★★★
          WeekView({
            vm: this.getOrCreateViewModelForWeek(week),
            week: week
          })
        }, (week: number) => week.toString())
      }
      .index(this.currentWeek - this.startWeek)
      .indicator(false)
      .loop(false)
      // ★★★ 关键：设置缓存数量，实现预加载 ★★★
      .cachedCount(1)
      .onChange((index: number) => {
        this.currentWeek = index + this.startWeek;
        // 切换时，确保目标页面的ViewModel已创建，以便aboutToAppear能加载数据
        this.getOrCreateViewModelForWeek(this.currentWeek);
      })
      .layoutWeight(1)

      // 周数选择器弹窗
      if (this.showWeekPicker) {
        this.WeekPickerDialog()
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  TopNavBar() {
    Row() {
      Text('<')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .onClick(() => this.goToPreviousWeek())
        .opacity(this.currentWeek > this.startWeek ? 1 : 0.3)
        .padding(8)

      Text(`第${this.currentWeek}周`)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)

      Text('⇌')
        .fontSize(18)
        .onClick(() => this.openWeekPicker())
        .padding(8)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  WeekPickerDialog() {
    Column() {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.4)')
        .onClick(() => {
          this.showWeekPicker = false;
        })

      // 底部弹窗内容
      Column() {
        // 顶部指示条
        Column()
          .width(36)
          .height(4)
          .backgroundColor('#D1D1D6')
          .borderRadius(2)
          .margin({ top: 8, bottom: 16 })

        // 标题
        Text('选择周数')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 20 })

        // 滚轮选择器
        TextPicker({
          range: this.weekNumbers.map(week => `第${week}周`),
          selected: this.currentWeek - this.startWeek
        })
          .onChange((value: string | string[], index: number | number[]) => {
            // 处理单选情况
            if (typeof index === 'number') {
              const selectedWeek = this.weekNumbers[index];
              this.jumpToWeek(selectedWeek);
            }
          })
          .backgroundColor(Color.White)
          .height(200)
          .margin({ bottom: 20 })

        // 确定按钮
        Button('确定')
          .width('100%')
          .height(48)
          .backgroundColor('#007AFF')
          .fontColor(Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .onClick(() => {
            this.showWeekPicker = false;
          })
          .margin({ bottom: 20 })
      }
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 16, topRight: 16 })
      .padding({ left: 20, right: 20 })
      .alignItems(HorizontalAlign.Center)
      .position({ x: 0, y: '100%' })
      .translate({ x: 0, y: '-100%' })
      .animation({
        duration: 300,
        curve: Curve.EaseOut
      })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(999)
    .justifyContent(FlexAlign.End)
  }
}