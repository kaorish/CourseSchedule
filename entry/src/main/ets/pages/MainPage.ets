import { SettingsViewModel } from '../viewmodel/SettingsViewModel';
import { TodayScheduleViewModel, TodayCourseResponse } from '../viewmodel/TodayScheduleViewModel';
import { WeeklyCourseViewModel } from '../viewmodel/WeeklyCourseViewModel';
import { Index } from './Index';
import { TodaySchedule } from './TodaySchedule';
import { Settings } from './Settings';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { common } from '@kit.AbilityKit';
import { AppSettings } from '../common/AppSettings';
import { NotificationService } from '../service/NotificationService';
import { TimeSlot } from '../model/TimeSlot';

@Entry
@Component
struct MainPage {
  @State currentTabIndex: number = 1;
  private controller: TabsController = new TabsController();

  @Provide('weeklyCourseVM') weeklyCourseVM: WeeklyCourseViewModel = new WeeklyCourseViewModel();
  @Provide('todayScheduleVM') todayScheduleVM: TodayScheduleViewModel = new TodayScheduleViewModel();
  @Provide('settingsVM') settingsVM: SettingsViewModel = new SettingsViewModel();

  @Watch('onAdvanceMinutesChange')
  @StorageLink(AppSettings.ADVANCE_MINUTES_KEY) advanceMinutes: number = 5;

  private periodTimeMap: Map<string, TimeSlot> = new Map([
    ['1', new TimeSlot('1', '08:30', '09:15')], ['2', new TimeSlot('2', '09:20', '10:05')],
    ['3', new TimeSlot('3', '10:25', '11:10')], ['4', new TimeSlot('4', '11:15', '12:00')],
    ['5', new TimeSlot('5', '14:00', '14:45')], ['6', new TimeSlot('6', '14:50', '15:35')],
    ['7', new TimeSlot('7', '15:55', '16:40')], ['8', new TimeSlot('8', '16:45', '17:30')],
    ['9', new TimeSlot('9', '19:00', '19:45')], ['10', new TimeSlot('10', '19:50', '20:35')]
  ]);

  onAdvanceMinutesChange(): void {
    console.log(`[MainPage] Notification setting changed to ${this.advanceMinutes} minutes. Rescheduling...`);
    this.scheduleTodayNotifications();
  }

  /**
   * ★★★ 核心修正 #1：将 aboutToAppear 声明为 async 函数 ★★★
   * 这样我们就可以在函数内部使用 await 来等待异步操作完成
   */
  async aboutToAppear() {
    console.log('[MainPage] Appearing. Initializing permissions and notifications.');

    // ★★★ 核心修正 #2：等待权限请求完成后，再决定是否执行下一步 ★★★
    const hasPermission = await this.requestNotificationPermission(getContext(this) as common.UIAbilityContext);

    if (hasPermission) {
      console.log('[MainPage] Permission granted. Proceeding to schedule notifications.');
      this.scheduleTodayNotifications();
    } else {
      console.log('[MainPage] Permission denied. Skipping notification scheduling.');
    }
  }

  async scheduleTodayNotifications() {
    const context = getContext(this) as common.UIAbilityContext;
    console.log('[MainPage] Running notification scheduling...');
    await NotificationService.cancelAllReminders();
    const courses: TodayCourseResponse[] = await this.todayScheduleVM.loadTodayCourses();
    if (!courses || courses.length === 0) {
      console.log('[MainPage] No courses for today. Skipping notification scheduling.');
      return;
    }
    console.log(`[MainPage] Found ${courses.length} courses. Scheduling with ${this.advanceMinutes} minutes advance.`);
    for (const course of courses) {
      const timeSlot = this.periodTimeMap.get(course.startPeriod.toString());
      if (!timeSlot) continue;
      const now = new Date();
      const timeParts = timeSlot.startTime.split(':').map(Number);
      const courseStartTime = new Date(now.getFullYear(), now.getMonth(), now.getDate(), timeParts[0], timeParts[1]);
      try {
        await NotificationService.scheduleCourseNotification(course.name, courseStartTime, this.advanceMinutes, context);
      } catch (e) {
        const error = e as Error;
        console.error(`[MainPage] Failed to schedule for course: ${course.name}. Reason: ${error.message}`);
      }
    }
  }

  /**
   * ★★★ 核心修正 #3：让函数返回一个布尔值，告诉调用者权限是否成功获取 ★★★
   */
  async requestNotificationPermission(context: common.UIAbilityContext): Promise<boolean> {
    try {
      let atManager = abilityAccessCtrl.createAtManager();
      const permissions: Array<Permissions> = ['ohos.permission.PUBLISH_AGENT_REMINDER'];
      // requestPermissionsFromUser 会等待用户点击弹窗
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      // 检查授权结果，如果所有权限都被授予（grantStatus都为0），则认为成功
      const allGranted = result.authResults.every(status => status === 0);
      if (!allGranted) {
        console.warn('Not all reminder permissions were granted by the user.');
        return false;
      }

      let isEnabled = await notificationManager.isNotificationEnabled();
      if (!isEnabled) {
        // 引导用户开启，但这里我们无法得知用户最终是否开启，暂时假设他会开启
        await notificationManager.requestEnableNotification();
      }
      return true; // 所有流程走完，返回成功
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to request permission. Code: ${err.code}, message: ${err.message}`);
      return false; // 发生任何错误都返回失败
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
      TabContent() { TodaySchedule() }.tabBar(this.TabBuilder('今日', 0, '📚'))
      TabContent() { Index() }.tabBar(this.TabBuilder('课程表', 1, '📅'))
      TabContent() { Settings() }.tabBar(this.TabBuilder('设置', 2, '⚙️'))
    }
    .onChange((index: number) => { this.currentTabIndex = index; })
    .barWidth('100%').barHeight(60).backgroundColor('#F1F3F5').animationDuration(200)
  }

  @Builder TabBuilder(title: string, index: number, icon: string) {
    Column({ space: 4 }) {
      Text(icon).fontSize(24)
      Text(title).fontSize(12).fontColor(this.currentTabIndex === index ? '#007DFF' : '#666666')
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}