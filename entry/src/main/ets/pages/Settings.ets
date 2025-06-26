import { SettingsViewModel } from '../viewmodel/SettingsViewModel';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { Semester } from '../model/Semester';
import { AppSettings } from '../common/AppSettings';

/**
 * 为“通知提前时间”选项定义一个明确的类
 */
class TimeOption {
  label: string;
  value: number;

  constructor(label: string, value: number) {
    this.label = label;
    this.value = value;
  }
}

/**
 * “设置”组件
 */
@Component
export struct Settings {
  @Consume('settingsVM') private settingsVM: SettingsViewModel;
  @StorageLink(AppSettings.ADVANCE_MINUTES_KEY) advanceMinutes: number = 10;

  private totalWeeksOptions: string[] = ((): string[] => {
    const options: string[] = [];
    for (let i = 1; i <= 25; i++) {
      options.push(`${i} 周`);
    }
    return options;
  })();

  private advanceTimeOptions: TimeOption[] = [
    new TimeOption('5 分钟', 5),
    new TimeOption('10 分钟', 10),
    new TimeOption('15 分钟', 15),
    new TimeOption('30 分钟', 30),
  ];

  aboutToAppear() {
    this.settingsVM.init();
  }

  displaySemesterPicker(): void {
    if (!this.settingsVM.semesters || this.settingsVM.semesters.length === 0) {
      promptAction.showToast({ message: '暂无学期数据' });
      return;
    }
    const semesterNames = this.settingsVM.semesters.map((s: Semester) => s.name);
    const currentIndex = this.settingsVM.semesters.findIndex((s: Semester) => s.id === this.settingsVM.currentSemesterId);
    TextPickerDialog.show({
      range: semesterNames,
      selected: currentIndex >= 0 ? currentIndex : 0,
      onAccept: (value?: TextPickerResult) => {
        if (value && typeof value.index === 'number') {
          const selectedSemester = this.settingsVM.semesters[value.index];
          if (selectedSemester && selectedSemester.id !== this.settingsVM.currentSemesterId) {
            this.settingsVM.setCurrentSemester(selectedSemester.id);
          }
        }
      }
    });
  }

  displayDatePicker(): void {
    const currentSelectedDate = new Date(this.settingsVM.startDate);
    const selectedDate = isNaN(currentSelectedDate.getTime()) ? new Date() : currentSelectedDate;
    DatePickerDialog.show({
      start: new Date('2020-01-01'),
      end: new Date('2030-12-31'),
      selected: selectedDate,
      onAccept: (value?: DatePickerResult) => {
        if (value && value.year !== undefined && value.month !== undefined && value.day !== undefined) {
          const month = (value.month + 1).toString().padStart(2, '0');
          const day = value.day.toString().padStart(2, '0');
          const formattedDate = `${value.year}-${month}-${day}`;
          this.settingsVM.updateSemesterDetails(this.settingsVM.currentSemesterId, { startDate: formattedDate });
        }
      }
    });
  }

  displayTotalWeeksPicker(): void {
    TextPickerDialog.show({
      range: this.totalWeeksOptions,
      selected: this.settingsVM.totalWeeks > 0 ? this.settingsVM.totalWeeks - 1 : 19,
      onAccept: (value?: TextPickerResult) => {
        if (value && typeof value.value === 'string') {
          const selectedWeeks = parseInt(value.value.split(' ')[0]);
          this.settingsVM.updateSemesterDetails(this.settingsVM.currentSemesterId, { totalWeeks: selectedWeeks });
        }
      }
    });
  }

  displayTimePicker(): void {
    const timeLabels = this.advanceTimeOptions.map((opt: TimeOption) => opt.label);
    const currentIndex = this.advanceTimeOptions.findIndex((opt: TimeOption) => opt.value === this.advanceMinutes);
    TextPickerDialog.show({
      range: timeLabels,
      selected: currentIndex >= 0 ? currentIndex : 1,
      onAccept: (value?: TextPickerResult) => {
        if (value && typeof value.index === 'number') {
          this.advanceMinutes = this.advanceTimeOptions[value.index].value;
          promptAction.showToast({ message: '通知设置已更新' });
        }
      }
    });
  }

  /**
   * 可点击的设置项构建器
   */
  @Builder
  ClickableSettingItem(title: string, onClick: () => void) {
    Row() {
      Text(title).fontSize(18).layoutWeight(1);
      Text('>').fontSize(16).fontColor('#666666');
    }
    .width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 })
    .onClick(onClick);
  }

  /**
   * 只读的设置项构建器
   */
  @Builder
  ReadOnlySettingItem(title: string, value: string) {
    Row() {
      Text(title).fontSize(18).layoutWeight(1);
      Text(value).fontSize(16).fontColor('#666666');
    }
    .width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 });
  }

  build() {
    Column() {
      Row() {
        Text('设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .layoutWeight(1);
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.Center);

      if (this.settingsVM.isLoading) {
        LoadingProgress().margin({ top: 20 });
      } else if (this.settingsVM.errorMessage) {
        Text(this.settingsVM.errorMessage).fontColor(Color.Red).margin({ top: 20 });
      }

      Scroll() {
        Column({ space: 10 }) {
          // 使用新的构建器，不再传递 value
          this.ClickableSettingItem('课程管理', () => { router.pushUrl({ url: 'pages/CourseManage' }); });
          Divider().width('85%').height(1).color('#E0E0E0').margin({ bottom: 5 });

          this.ClickableSettingItem('切换学期', () => { this.displaySemesterPicker(); });
          Divider().width('85%').height(1).color('#E0E0E0').margin({ bottom: 5 });

          this.ClickableSettingItem('设置学期开始日期', () => { this.displayDatePicker(); });
          Divider().width('85%').height(1).color('#E0E0E0').margin({ bottom: 5 });

          this.ClickableSettingItem('设置学期总周数', () => { this.displayTotalWeeksPicker(); });
          Divider().width('85%').height(1).color('#E0E0E0').margin({ bottom: 5 });

          this.ReadOnlySettingItem('当前的周数', `第 ${this.settingsVM.currentWeekNumber} 周`);
          Divider().width('85%').height(1).color('#E0E0E0').margin({ bottom: 5 });

          Row() {
            Text('是否显示周末').fontSize(18).layoutWeight(1);
            Toggle({ type: ToggleType.Switch, isOn: this.settingsVM.showWeekend })
              .onChange((isOn: boolean) => { this.settingsVM.showWeekend = isOn; });
          }.width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 });
          Divider().width('85%').height(1).color('#E0E0E0').margin({ bottom: 5 });

          Row() {
            Text('是否显示非本周课程').fontSize(18).layoutWeight(1);
            Toggle({ type: ToggleType.Switch, isOn: this.settingsVM.showNonCurrentWeekCourses })
              .onChange((isOn: boolean) => { this.settingsVM.showNonCurrentWeekCourses = isOn; });
          }.width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 });
          Divider().width('85%').height(1).color('#E0E0E0').margin({ bottom: 5 });

          this.ClickableSettingItem('通知提前分钟', () => { this.displayTimePicker(); });
        }
        .width('100%').alignItems(HorizontalAlign.Center).padding({ top: 20, bottom: 20 });
      }
      .layoutWeight(1);
    }
    .width('100%').height('100%').backgroundColor('#ffffff');
  }
}