import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
// 使用您代码中已验证的正确模块
import reminderAgentManager from '@ohos.reminderAgentManager';

export class NotificationService {

  /**
   * 封装了 publishReminder 的 Promise 版本，以便在应用中继续使用 async/await
   * @param request 要发布的提醒请求
   * @returns Promise<number> 成功时返回 reminderId
   */
  private static publishReminderAsPromise(request: reminderAgentManager.ReminderRequest): Promise<number> {
    return new Promise((resolve, reject) => {
      // ★★★ 核心修正 #1：使用您代码中验证过的 publishReminder 函数，并传入回调 ★★★
      reminderAgentManager.publishReminder(request, (err: BusinessError, reminderId: number) => {
        if (err) {
          console.error(`[NotificationService] Error publishing reminder. Code: ${err.code}, message: ${err.message}`);
          // 当发生错误时，拒绝 Promise
          reject(new Error(`Error publishing reminder: ${err.message}`));
        } else {
          // 成功时，解析 Promise 并返回 reminderId
          resolve(reminderId);
        }
      });
    });
  }

  static async scheduleCourseNotification(
    courseName: string,
    courseTime: Date,
    advanceMinutes: number,
    context: common.UIAbilityContext
  ): Promise<number> {

    const triggerTimestamp = courseTime.getTime() - advanceMinutes * 60 * 1000;
    if (triggerTimestamp < Date.now()) {
      console.warn("[NotificationService] The scheduled time is in the past. Reminder not set.");
      return -1;
    }
    const triggerDateTime = new Date(triggerTimestamp);

    try {
      // ★★★ 核心修正 #2：构建与您代码中 calendarEvent 结构一致的对象 ★★★
      const reminderRequest: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: triggerDateTime.getFullYear(),
          month: triggerDateTime.getMonth() + 1,
          day: triggerDateTime.getDate(),
          hour: triggerDateTime.getHours(),
          minute: triggerDateTime.getMinutes(),
        },
        title: '上课提醒 ⏰',
        content: `${courseName} 将在 ${advanceMinutes} 分钟后开始！`,
        wantAgent: {
          pkgName: context.abilityInfo.bundleName,
          abilityName: context.abilityInfo.name,
        }
      };

      // 调用我们封装好的 Promise 版本的发布函数
      const reminderId = await NotificationService.publishReminderAsPromise(reminderRequest);
      console.log(`[NotificationService] SUCCESS! Reminder for '${courseName}' published with ID: ${reminderId}`);
      return reminderId;

    } catch (error) {
      console.error(`[MainPage] Failed to schedule for course: ${courseName}. Reason: ${(error as Error).message}`);
      // 抛出错误或返回错误代码
      return -1;
    }
  }

  // cancelAllReminders 方法很可能支持 async/await，我们保持现状，因为它更简洁
  static async cancelAllReminders(): Promise<void> {
    try {
      await reminderAgentManager.cancelAllReminders();
      console.log('[NotificationService] All existing reminders from this app have been cancelled.');
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[NotificationService] Failed to cancel all reminders. Code: ${err.code}, message: ${err.message}`);
    }
  }
}