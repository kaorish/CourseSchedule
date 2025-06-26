// 文件路径: entry/src/main/ets/pages/Index.ets

import { WeeklyCourseViewModel } from '../viewmodel/WeeklyCourseViewModel'
import { WeekView } from './WeekView'
import router from '@ohos.router'
import { AppSettings } from '../common/AppSettings';

type WeekViewModelMap = Map<number, WeeklyCourseViewModel>;

@Component
export struct Index {
  @State weekViewModels: WeekViewModelMap = new Map();
  @StorageLink(AppSettings.CALCULATED_CURRENT_WEEK_KEY)
  @Watch('onCurrentWeekChange')
  private currentWeek: number = 1;

  @State showWeekPicker: boolean = false;

  private swiperController: SwiperController = new SwiperController();
  private readonly totalWeeks: number = 20;
  private readonly startWeek: number = 1;
  private weekNumbers: number[] = [];

  onCurrentWeekChange(): void {
    const targetIndex = this.currentWeek - this.startWeek;
    if (targetIndex >= 0 && targetIndex < this.totalWeeks) {
      console.log(`[Index.ets] currentWeek changed to ${this.currentWeek}. Jumping Swiper to index: ${targetIndex}`);
      this.swiperController.changeIndex(targetIndex, false);
    }
  }

  aboutToAppear() {
    if (this.weekNumbers.length === 0) {
      for (let i = this.startWeek; i <= this.totalWeeks; i++) {
        this.weekNumbers.push(i);
      }
    }
    this.getOrCreateViewModelForWeek(this.currentWeek);
    this.onCurrentWeekChange();
  }

  getOrCreateViewModelForWeek(week: number): WeeklyCourseViewModel {
    if (!this.weekViewModels.has(week)) {
      this.weekViewModels.set(week, new WeeklyCourseViewModel());
    }
    return this.weekViewModels.get(week)!;
  }

  goToPreviousWeek(): void { if (this.currentWeek > this.startWeek) this.swiperController.showPrevious(); }
  goToNextWeek(): void { if (this.currentWeek < this.totalWeeks) this.swiperController.showNext(); }

  jumpToWeek(targetWeek: number): void {
    if (targetWeek >= this.startWeek && targetWeek <= this.totalWeeks) {
      this.currentWeek = targetWeek;
      this.getOrCreateViewModelForWeek(targetWeek);
      const targetIndex = targetWeek - this.startWeek;
      this.swiperController.changeIndex(targetIndex);
    }
  }

  openWeekPicker(): void {
    this.showWeekPicker = true;
  }

  build() {
    Column() {
      this.TopNavBar()

      Swiper(this.swiperController) {
        ForEach(this.weekNumbers, (week: number) => {
          WeekView({
            vm: this.getOrCreateViewModelForWeek(week),
            week: week
          })
        }, (week: number) => week.toString())
      }
      .index(this.currentWeek - this.startWeek)
      .indicator(false)
      .loop(false)
      .cachedCount(1)
      .onChange((index: number) => {
        this.currentWeek = index + this.startWeek;
        this.getOrCreateViewModelForWeek(this.currentWeek);
      })
      .layoutWeight(1)

      if (this.showWeekPicker) {
        this.WeekPickerDialog()
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  // 【核心修正】恢复 TopNavBar 的干净状态
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
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.4)')
        .onClick(() => {
          this.showWeekPicker = false;
        })

      Column() {
        Column()
          .width(36)
          .height(4)
          .backgroundColor('#D1D1D6')
          .borderRadius(2)
          .margin({ top: 8, bottom: 16 })

        Text('选择周数')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 20 })

        TextPicker({
          range: this.weekNumbers.map(week => `第${week}周`),
          selected: this.currentWeek - this.startWeek
        })
          .onChange((value: string | string[], index: number | number[]) => {
            if (typeof index === 'number') {
              const selectedWeek = this.weekNumbers[index];
              this.jumpToWeek(selectedWeek);
            }
          })
          .backgroundColor(Color.White)
          .height(200)
          .margin({ bottom: 20 })

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