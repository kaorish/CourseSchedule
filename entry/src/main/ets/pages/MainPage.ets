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

  async aboutToAppear() {
    console.log('[MainPage] Appearing. Initializing settings and permissions.');

    try {
      await this.settingsVM.init();
      console.log('[MainPage] SettingsViewModel initialized and current week calculated.');
    } catch (e) {
      console.error(`[MainPage] Failed to initialize SettingsViewModel: ${(e as Error).message}`);
    }

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

  async requestNotificationPermission(context: common.UIAbilityContext): Promise<boolean> {
    try {
      let atManager = abilityAccessCtrl.createAtManager();
      const permissions: Array<Permissions> = ['ohos.permission.PUBLISH_AGENT_REMINDER'];
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      const allGranted = result.authResults.every(status => status === 0);
      if (!allGranted) {
        console.warn('Not all reminder permissions were granted by the user.');
        return false;
      }

      let isEnabled = await notificationManager.isNotificationEnabled();
      if (!isEnabled) {
        await notificationManager.requestEnableNotification();
      }
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to request permission. Code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
      TabContent() { TodaySchedule() }.tabBar(this.TabBuilder('今日', 0, '📚'))
      TabContent() { Index() }.tabBar(this.TabBuilder('课程表', 1, '📅'))
      TabContent() { Settings() }.tabBar(this.TabBuilder('设置', 2, '⚙️'))
    }
    .onChange((index: number) => { this.currentTabIndex = index; })
    .barWidth('100%')
    .barHeight(60)
    // 移除在 Tabs 上的边框和背景色，交由 TabBuilder 处理
    .animationDuration(200)
  }

  // 【核心修正】将分割线和背景色精确地应用到 TabBar 上
  @Builder TabBuilder(title: string, index: number, icon: string) {
    Column() {
      // 顶部分割线
      Divider().strokeWidth(1).color('#E0E0E0')
      // 原有的内容
      Column({ space: 4 }) {
        Text(icon).fontSize(24)
        Text(title).fontSize(12).fontColor(this.currentTabIndex === index ? '#007DFF' : '#666666')
      }
      .width('100%')
      .layoutWeight(1) // 确保内容区域占满剩余空间
      .justifyContent(FlexAlign.Center)
    }
    .backgroundColor(Color.White) // 将白色背景应用到每个 TabBar 的容器上
  }
}