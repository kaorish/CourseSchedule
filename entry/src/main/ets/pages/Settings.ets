import { SettingsViewModel } from '../viewmodel/SettingsViewModel';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { Semester } from '../model/Semester';
import { AppSettings } from '../common/AppSettings';

/**
 * “设置”组件
 */
@Component
export struct Settings {
  @State showTimePicker: boolean = false;
  @State showSemesterPicker: boolean = false;
  @State tempSelectedSemesterId: number = 0;

  @Consume('settingsVM') private settingsVM: SettingsViewModel;
  @StorageLink(AppSettings.ADVANCE_MINUTES_KEY) advanceMinutes: number = 10;

  // 最终修正：使用 for 循环来创建数组，彻底避免类型推断问题
  private totalWeeksOptions: string[] = ((): string[] => {
    const options: string[] = [];
    for (let i = 1; i <= 25; i++) {
      options.push(`${i} 周`);
    }
    return options;
  })();

  aboutToAppear() {
    this.settingsVM.init();
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
      },
      onCancel: () => {
        console.info('Date picker dialog was cancelled.');
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
      },
      onCancel: () => {
        console.info('Total weeks picker dialog was cancelled.');
      }
    });
  }

  @Builder
  SemesterPickerDialog() {
    Column() {
      Text('选择学期').fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 20 });
      Scroll() {
        Column() {
          ForEach(this.settingsVM.semesters, (semester: Semester) => {
            Row() {
              Text(semester.name).fontSize(16).layoutWeight(1);
              Radio({ value: semester.id.toString(), group: 'semesterGroup' })
                .checked(this.tempSelectedSemesterId === semester.id)
                .onChange(() => { this.tempSelectedSemesterId = semester.id; });
            }
            .width('100%').padding({ top: 10, bottom: 10 })
            .onClick(() => { this.tempSelectedSemesterId = semester.id; });
          }, (item: Semester) => item.id.toString())
        }
      }
      .height(200).margin({ bottom: 20 });
      Row({ space: 10 }) {
        Button('取消').onClick(() => { this.showSemesterPicker = false; }).backgroundColor('#f0f0f0').fontColor('#666666').layoutWeight(1);
        Button('确定').onClick(() => {
          this.showSemesterPicker = false;
          if (this.tempSelectedSemesterId !== 0 && this.tempSelectedSemesterId !== this.settingsVM.currentSemesterId) {
            this.settingsVM.setCurrentSemester(this.tempSelectedSemesterId);
          }
        }).layoutWeight(1);
      }.width('100%')
    }
    .width('80%').padding(20).backgroundColor(Color.White).borderRadius(12);
  }

  @Builder
  createTimeOption(minutes: number) {
    Row() {
      Text(`${minutes} 分钟`).fontSize(16).layoutWeight(1);
      Radio({ value: minutes.toString(), group: 'timeGroup' })
        .checked(this.advanceMinutes === minutes)
        .onChange(() => { this.advanceMinutes = minutes; });
    }.width('100%');
  }

  @Builder
  SettingItem(title: string, value: string, onClick: () => void, showArrow: boolean = true) {
    Row() {
      Text(title).fontSize(18).layoutWeight(1);
      Text(value).fontSize(16).fontColor('#666666').margin({ right: 10 });
      if (showArrow) {
        Text('>').fontSize(16).fontColor('#666666');
      }
    }
    .width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 })
    .onClick(onClick);
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
          this.SettingItem('课程管理', '编辑、删除课程信息', () => { router.pushUrl({ url: 'pages/CourseManage' }); });

          Divider().width('90%').height(1).color('#E0E0E0').margin({ top: 5, bottom: 5 });

          this.SettingItem('切换学期', this.settingsVM.semesters.find((s: Semester) => s.id === this.settingsVM.currentSemesterId)?.name ?? '加载中...', () => {
            this.tempSelectedSemesterId = this.settingsVM.currentSemesterId;
            this.showSemesterPicker = true;
          });

          this.SettingItem('设置学期开始日期', this.settingsVM.startDate, () => {
            this.displayDatePicker();
          });

          this.SettingItem('设置学期总周数', `${this.settingsVM.totalWeeks} 周`, () => {
            this.displayTotalWeeksPicker();
          });

          this.SettingItem('当前的周数', `第 ${this.settingsVM.currentWeekNumber} 周`, () => {}, false);

          Row() {
            Text('是否显示周末').fontSize(18).layoutWeight(1);
            Toggle({ type: ToggleType.Switch, isOn: this.settingsVM.showWeekend })
              .onChange((isOn: boolean) => { this.settingsVM.showWeekend = isOn; });
          }.width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 });

          Row() {
            Text('是否显示非本周课程').fontSize(18).layoutWeight(1);
            Toggle({ type: ToggleType.Switch, isOn: this.settingsVM.showNonCurrentWeekCourses })
              .onChange((isOn: boolean) => { this.settingsVM.showNonCurrentWeekCourses = isOn; });
          }.width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 });

          this.SettingItem('通知提前分钟', `${this.advanceMinutes} 分钟`, () => {
            this.showTimePicker = true;
          });
        }
        .width('100%').alignItems(HorizontalAlign.Center).padding({ top: 20, bottom: 20 });
      }
      .layoutWeight(1);

      if (this.showSemesterPicker) {
        Column() {
          this.SemesterPickerDialog();
        }
        .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.4)')
        .justifyContent(FlexAlign.Center).zIndex(20);
      }

      if (this.showTimePicker) {
        Column() {
          Column() {
            Text('选择通知提前时间').fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 20 });
            Column({ space: 10 }) {
              this.createTimeOption(5);
              this.createTimeOption(10);
              this.createTimeOption(15);
              this.createTimeOption(30);
            }
            Row({space:10}) {
              Button('取消').onClick(() => { this.showTimePicker = false; }).backgroundColor('#f0f0f0').fontColor('#666666').layoutWeight(1);
              Button('确定').onClick(() => {
                this.showTimePicker = false;
                promptAction.showToast({ message: '通知设置已更新', duration: 1000 });
              }).layoutWeight(1);
            }.width('100%').margin({ top: 20 });
          }.width('80%').padding(20).backgroundColor(Color.White).borderRadius(12);
        }
        .position({ x: 0, y: 0 }).width('100%').height('100%').zIndex(20)
        .justifyContent(FlexAlign.Center).backgroundColor('rgba(0,0,0,0.7)');
      }
    }
    .width('100%').height('100%').backgroundColor('#f5f5f5');
  }
}