import { SettingsViewModel } from '../viewmodel/SettingsViewModel'; // 导入我们新建的ViewModel
import promptAction from '@ohos.promptAction'; // 导入提示工具
import { Semester } from '../model/Semester';
import { AppSettings } from '../common/AppSettings'; // 导入全局状态键

/**
 * Settings 组件
 * 提供课程表相关的各项设置，包括学期管理、显示偏好和通知设置。
 */
@Component // 声明这是一个UI组件
struct Settings {
  // 控制“通知提前时间”选择器弹窗的显示与隐藏
  @State showTimePicker: boolean = false;
  // 控制“选择学期”弹窗的显示与隐藏
  @State showSemesterPicker: boolean = false;
  // 在学期选择器中临时存储用户选择的学期ID，待“确定”后才正式应用
  @State tempSelectedSemesterId: number = 0;



  // 注入 SettingsViewModel 实例
  @Consume('settingsVM') private settingsVM: SettingsViewModel;

  // ★★★ 核心修改：使用 @StorageLink 直接双向绑定到 AppStorage ★★★
  // 当UI修改这个变量时，AppStorage中的值会立即改变，反之亦然。
  // 这使得 MainPage 可以监听到此处的变更。
  @StorageLink(AppSettings.ADVANCE_MINUTES_KEY) advanceMinutes: number = 10; // 提供一个默认值，仅在首次创建时生效

  /**
   * 组件即将显示时调用。
   * 在这里初始化 ViewModel，加载学期数据。
   */
  aboutToAppear() {
    this.settingsVM.init(); // 调用 ViewModel 的初始化方法
  }

  /**
   * 自定义构建器：学期选择器弹窗。
   * 显示所有学期列表，允许用户选择一个学期。
   */
  @Builder
  SemesterPickerDialog() {
    Column() {
      Text('选择学期')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      // 可滚动的学期列表
      Scroll() {
        Column() {
          // 遍历 ViewModel 中的学期列表，为每个学期创建一个选项
          ForEach(this.settingsVM.semesters, (semester: Semester) => {
            Row() {
              Text(semester.name)
                .fontSize(16)
                .layoutWeight(1); // 文本占据剩余空间
              Radio({ value: semester.id.toString(), group: 'semesterGroup' })
                // 判断当前学期是否被选中
                .checked(this.settingsVM.currentSemesterId === semester.id)
                .onChange(() => {
                  this.tempSelectedSemesterId = semester.id; // 更新临时选中状态
                });
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .onClick(() => {
              // 允许点击整行来选中Radio
              this.tempSelectedSemesterId = semester.id;
            });
          }, (semester: Semester) => semester.id.toString()) // 提供唯一key
        }
        .width('100%')
      }
      .height(200) // 固定滚动区域高度
      .margin({ bottom: 20 });

      // 弹窗底部按钮区域
      Row() {
        Button('取消')
          .onClick(() => {
            this.showSemesterPicker = false; // 关闭弹窗
          })
          .backgroundColor('#f0f0f0')
          .fontColor('#666666')
          .width('45%'); // 按钮宽度

        Button('确定')
          .onClick(() => {
            this.showSemesterPicker = false; // 关闭弹窗
            // 如果临时选中的学期ID不为0且与当前学期ID不同，则更新 ViewModel
            if (this.tempSelectedSemesterId !== 0 && this.tempSelectedSemesterId !== this.settingsVM.currentSemesterId) {
              this.settingsVM.setCurrentSemester(this.tempSelectedSemesterId);
            }
          })
          .width('45%'); // 按钮宽度
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween) // 按钮之间等宽间距
    }
    .width('80%') // 弹窗内容宽度
    .padding(20)
    .backgroundColor('#ffffff')
    .borderRadius(12);
  }

  /**
   * 组件构建方法，定义UI布局。
   */
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .layoutWeight(1); // 文本占据所有可用空间
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.Center);

      // 加载状态和错误信息显示
      if (this.settingsVM.isLoading) {
        Progress({ value: 50 }) // 显示加载指示器
          .margin({ top: 20 });
      } else if (this.settingsVM.errorMessage) {
        Text(this.settingsVM.errorMessage) // 显示错误信息
          .fontColor(Color.Red)
          .margin({ top: 20 });
      }

      // 设置项列表
      Column({ space: 10 }) { // 设置项之间的垂直间距
        // ... (其他所有设置项保持不变)
        this.SettingItem('切换周数 (选择学期)', `当前学期：${this.settingsVM.startDate} - ${this.settingsVM.totalWeeks}周`, () => {
          this.tempSelectedSemesterId = this.settingsVM.currentSemesterId;
          this.showSemesterPicker = true;
        });
        this.SettingItem('设置学期开始日期', this.settingsVM.startDate, () => {
          promptAction.showToast({ message: '日期选择功能待实现' });
        });
        this.SettingItem('设置学期总周数', `${this.settingsVM.totalWeeks} 周`, () => {
          promptAction.showToast({ message: '周数输入功能待实现' });
        });
        this.SettingItem('当前的周数', `${this.settingsVM.currentWeekNumber} 周`, () => {
          promptAction.showToast({ message: '此功能为静态显示，不进行修改' });
        });
        Row() {
          Text('是否显示周末')
            .fontSize(18)
            .layoutWeight(1);
          Toggle({ type: ToggleType.Switch, isOn: this.settingsVM.showWeekend })
            .onChange((isOn: boolean) => {
              this.settingsVM.showWeekend = isOn;
              promptAction.showToast({ message: `显示周末: ${isOn ? '是' : '否'}` });
            });
        }
        .width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 });
        Row() {
          Text('是否显示非本周课程')
            .fontSize(18)
            .layoutWeight(1);
          Toggle({ type: ToggleType.Switch, isOn: this.settingsVM.showNonCurrentWeekCourses })
            .onChange((isOn: boolean) => {
              this.settingsVM.showNonCurrentWeekCourses = isOn;
              promptAction.showToast({ message: `显示非本周课程: ${isOn ? '是' : '否'}` });
            });
        }
        .width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 });


        // ★★★ 核心修改：SettingItem 的 value 直接绑定到 @StorageLink 的变量 ★★★
        this.SettingItem('通知提前分钟', `${this.advanceMinutes} 分钟`, () => {
          this.showTimePicker = true; // 显示时间选择器弹窗
        });

      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)
      .padding({ top: 20, bottom: 20 });

      // 时间选择器弹窗
      if (this.showTimePicker) {
        Column() {
          Column() {
            Text('选择通知提前时间')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 20 });
            Column({ space: 10 }) {
              this.createTimeOption(5);
              this.createTimeOption(10);
              this.createTimeOption(15);
              this.createTimeOption(30);
            }
            Row() {
              Button('取消')
                .onClick(() => { this.showTimePicker = false; })
                .backgroundColor('#f0f0f0').fontColor('#666666').width('45%');
              Button('确定')
                .onClick(() => {
                  this.showTimePicker = false;
                  promptAction.showToast({ message: '通知设置已更新', duration: 1000 });
                })
                .width('45%');
            }
            .width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ top: 20 });
          }
          .width('80%').padding(20).backgroundColor('#ffffff').borderRadius(12);
        }
        .position({ x: 0, y: 0 }).width('100%').height('100%').zIndex(1000)
        .justifyContent(FlexAlign.Center).backgroundColor(Color.Black).opacity(0.7);
      }

      // 学期选择器弹窗
      if (this.showSemesterPicker) {
        Column() {
          this.SemesterPickerDialog();
        }
        .position({ x: 0, y: 0 }).width('100%').height('100%').zIndex(1000)
        .justifyContent(FlexAlign.Center).backgroundColor(Color.Black).opacity(0.7);
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5');
  }

  /**
   * 自定义构建器：单个设置项的通用布局。
   */
  @Builder
  SettingItem(title: string, value: string, onClick: () => void) {
    Row() {
      Text(title).fontSize(18).layoutWeight(1);
      Text(value).fontSize(16).fontColor('#666666').margin({ right: 10 });
      Text('>').fontSize(16).fontColor('#666666').margin({ right: 10 });
    }
    .width('90%').padding(15).backgroundColor(Color.White).borderRadius(12).margin({ top: 10 }).onClick(onClick);
  }

  /**
   * 自定义构建器：通知提前时间的单选选项。
   */
  @Builder
  createTimeOption(minutes: number) {
    Row() {
      Text(`${minutes} 分钟`)
        .fontSize(16)
        .layoutWeight(1);
      // ★★★ 核心修改：Radio 直接和 @StorageLink 的变量绑定 ★★★
      Radio({ value: minutes.toString(), group: 'timeGroup' })
        .checked(this.advanceMinutes === minutes)
        .onChange(() => {
          this.advanceMinutes = minutes; // 直接修改此变量，即可更新全局AppStorage
        });
    }
    .width('100%');
  }
}

export { Settings };