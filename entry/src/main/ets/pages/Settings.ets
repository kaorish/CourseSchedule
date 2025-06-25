// 文件路径: entry/src/main/ets/pages/Settings.ets

import { SettingsViewModel } from '../viewmodel/SettingsViewModel';
import promptAction from '@ohos.promptAction';
import { Semester } from '../model/Semester';
import { AppSettings } from '../common/AppSettings';

function formatDate(date: Date): string {
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}

@Component
export struct Settings {
  // 本地UI状态，用于控制弹窗显示
  @State showSemesterPicker: boolean = false;
  @State tempSelectedSemesterId: number = 0;
  @State showDatePicker: boolean = false;
  @State showWeeksEditor: boolean = false;
  @State tempTotalWeeks: string = '0';

  // 获取ViewModel实例，用于调用其方法
  @Consume('settingsVM') private settingsVM: SettingsViewModel;

  // --- 核心：UI组件直接通过@StorageLink订阅AppStorage中的数据 ---
  @StorageLink(AppSettings.CURRENT_SEMESTER_ID_KEY)
  private currentSemesterId: number = -1;

  @StorageLink(AppSettings.CURRENT_SEMESTER_START_DATE_KEY)
  private semesterStartDate: string = '加载中...';

  @StorageLink(AppSettings.CURRENT_SEMESTER_TOTAL_WEEKS_KEY)
  private semesterTotalWeeks: number = 0;

  @StorageLink(AppSettings.ADVANCE_MINUTES_KEY)
  private advanceMinutes: number = 5;

  // 页面原始的、与AppStorage无关的状态
  @State showWeekend: boolean = true;
  @State showNonCurrentWeekCourses: boolean = false;

  aboutToAppear() {
    // 页面出现时，让ViewModel去执行初始化逻辑（获取网络数据、同步AppStorage）
    this.settingsVM.init();
  }

  // --- 所有弹窗和UI的构建代码 ---
  @Builder
  DatePickerDialog() {
    DatePicker({
      start: new Date('2020-01-01'),
      end: new Date('2030-12-31'),
      selected: new Date(this.semesterStartDate)
    })
      .width('80%')
      .backgroundColor(Color.White)
      .borderRadius(12)
      .onChange((value: DatePickerResult) => {
        if (value && value.year !== undefined && value.month !== undefined && value.day !== undefined) {
          const newSelectedDate = new Date(value.year, value.month, value.day);
          const newDateStr = formatDate(newSelectedDate);
          this.settingsVM.updateSemesterDetails(this.currentSemesterId, newDateStr, this.semesterTotalWeeks);
        }
      })
  }

  @Builder
  WeeksEditorDialog() {
    Column() {
      Text('设置学期总周数').fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 20 });
      TextInput({ text: this.tempTotalWeeks, placeholder: '输入1-25之间的数字' })
        .type(InputType.Number).width('80%')
        .onChange((value) => { this.tempTotalWeeks = value; });
      Row({ space: 10 }) {
        Button('取消').onClick(() => this.showWeeksEditor = false).layoutWeight(1).backgroundColor(Color.Gray).fontColor(Color.White);
        Button('确定').onClick(() => {
          const weeks = parseInt(this.tempTotalWeeks);
          if (isNaN(weeks) || weeks <= 0 || weeks > 25) {
            promptAction.showToast({ message: '请输入有效的周数 (1-25)' });
            return;
          }
          this.settingsVM.updateSemesterDetails(this.currentSemesterId, this.semesterStartDate, weeks);
          this.showWeeksEditor = false;
        }).layoutWeight(1);
      }.width('80%').margin({ top: 20 });
    }.width('80%').padding(20).backgroundColor(Color.White).borderRadius(12);
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
                .checked(this.currentSemesterId === semester.id)
                .onChange(() => { this.tempSelectedSemesterId = semester.id; });
            }.width('100%').padding({ top: 10, bottom: 10 })
            .onClick(() => { this.tempSelectedSemesterId = semester.id; });
          }, (semester: Semester) => semester.id.toString())
        }.width('100%');
      }.height(200).margin({ bottom: 20 });
      Row() {
        Button('取消').onClick(() => { this.showSemesterPicker = false; }).backgroundColor('#f0f0f0').fontColor('#666666').width('45%');
        Button('确定').onClick(() => {
          this.showSemesterPicker = false;
          if (this.tempSelectedSemesterId !== 0 && this.tempSelectedSemesterId !== this.currentSemesterId) {
            this.settingsVM.switchActiveSemester(this.tempSelectedSemesterId);
          }
        }).width('45%');
      }.width('100%').justifyContent(FlexAlign.SpaceBetween);
    }.width('80%').padding(20).backgroundColor(Color.White).borderRadius(12);
  }

  build() {
    Column() {
      Row() {
        Text('设置').fontSize(24).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).layoutWeight(1);
      }.width('100%').height(56).backgroundColor(Color.White).justifyContent(FlexAlign.Center);

      if (this.settingsVM.isLoading && !this.showDatePicker && !this.showWeeksEditor) {
        LoadingProgress().margin({ top: 20 });
      } else if (this.settingsVM.errorMessage) {
        Text(this.settingsVM.errorMessage).fontColor(Color.Red).margin({ top: 20 });
      }

      // 整个设置列表放在一个可滚动容器中
      Scroll() {
        Column({ space: 10 }) {
          this.SettingItem('切换周数 (选择学期)', `当前学期：${this.semesterStartDate} - ${this.semesterTotalWeeks}周`, () => {
            this.tempSelectedSemesterId = this.currentSemesterId;
            this.showSemesterPicker = true;
          });
          this.SettingItem('设置学期开始日期', this.semesterStartDate, () => {
            if (this.currentSemesterId > 0) { this.showDatePicker = true; }
            else { promptAction.showToast({ message: '请先选择一个学期' }); }
          });
          this.SettingItem('设置学期总周数', `${this.semesterTotalWeeks} 周`, () => {
            if (this.currentSemesterId > 0) {
              this.tempTotalWeeks = this.semesterTotalWeeks.toString();
              this.showWeeksEditor = true;
            } else { promptAction.showToast({ message: '请先选择一个学期' }); }
          });
          this.SettingItem('当前的周数', `${this.settingsVM.currentWeekNumber} 周`, () => {});
          Row() {
            Text('是否显示周末').fontSize(18).layoutWeight(1);
            Toggle({ type: ToggleType.Switch, isOn: this.showWeekend }).onChange((isOn: boolean) => { this.showWeekend = isOn; });
          }.width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 });
          Row() {
            Text('是否显示非本周课程').fontSize(18).layoutWeight(1);
            Toggle({ type: ToggleType.Switch, isOn: this.showNonCurrentWeekCourses }).onChange((isOn: boolean) => { this.showNonCurrentWeekCourses = isOn; });
          }.width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 });
          this.SettingItem('通知提前分钟', `${this.advanceMinutes} 分钟`, () => { this.showDatePicker = true; });
        }.width('100%').alignItems(HorizontalAlign.Center).padding({ top: 20, bottom: 20 });
      }.layoutWeight(1)
      .visibility(this.settingsVM.isLoading ? Visibility.Hidden : Visibility.Visible)

      // --- 以下是所有弹窗的定义，代码保持原样 ---
      if (this.showDatePicker) {
        Column() { this.DatePickerDialog(); Button('关闭').onClick(() => this.showDatePicker = false).margin({ top: 20 }); }
        .position({ x: 0, y: 0 }).width('100%').height('100%').zIndex(1000).justifyContent(FlexAlign.Center).backgroundColor('rgba(0,0,0,0.4)');
      }
      if (this.showWeeksEditor) {
        Column() { this.WeeksEditorDialog(); }
        .position({ x: 0, y: 0 }).width('100%').height('100%').zIndex(1000).justifyContent(FlexAlign.Center).backgroundColor('rgba(0,0,0,0.4)');
      }
      if (this.showSemesterPicker) {
        Column() { this.SemesterPickerDialog(); }
        .position({ x: 0, y: 0 }).width('100%').height('100%').zIndex(1000).justifyContent(FlexAlign.Center).backgroundColor('rgba(0,0,0,0.7)');
      }
      // ... 您原始的通知时间选择弹窗也可以放在这里
    }.width('100%').height('100%').backgroundColor('#f5f5f5');
  }

  // SettingItem @Builder保持原样
  @Builder
  SettingItem(title: string, value: string, onClick: () => void) {
    Row() {
      Text(title).fontSize(18).layoutWeight(1);
      Text(value).fontSize(16).fontColor('#666666').margin({ right: 10 });
      Text('>').fontSize(16).fontColor('#666666').margin({ right: 10 });
    }.width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 }).onClick(onClick);
  }
}