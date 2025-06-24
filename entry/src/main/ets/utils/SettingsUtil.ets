import dataPreferences from '@ohos.data.preferences'; // ★★★ 修正 #1：使用正确的模块路径
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const PREF_FILE_NAME = 'settings_pref'; // Preferences文件名
const KEY_ADVANCE_MINUTES = 'notification_advance_minutes'; // 存储提前分钟数的键

let pref: dataPreferences.Preferences | null = null;

// 异步获取Preferences实例的函数
async function getPrefInstance(context: common.UIAbilityContext): Promise<dataPreferences.Preferences> {
  if (pref === null) {
    try {
      pref = await dataPreferences.getPreferences(context, PREF_FILE_NAME);
    } catch (err) {
      const error = err as BusinessError; // 类型断言
      console.error(`[SettingsUtil] Failed to get preferences instance. Code: ${error.code}, message: ${error.message}`);
      // ★★★ 修正 #2：抛出标准的Error对象
      throw new Error(`Failed to get preferences instance. Code: ${error.code}, message: ${error.message}`);
    }
  }
  return pref;
}

export class SettingsUtil {
  /**
   * 保存提前通知的分钟数
   * @param context 应用上下文
   * @param minutes 分钟数
   */
  static async setAdvanceMinutes(context: common.UIAbilityContext, minutes: number): Promise<void> {
    try {
      const preferences = await getPrefInstance(context);
      await preferences.put(KEY_ADVANCE_MINUTES, minutes);
      await preferences.flush();
      console.log(`[SettingsUtil] Advance minutes saved: ${minutes}`);
    } catch (err) {
      // 捕获并处理错误，但不向外抛出，避免程序崩溃
      const error = err as BusinessError;
      console.error(`[SettingsUtil] Failed to save advance minutes. Code: ${error.code}, message: ${error.message}`);
    }
  }

  /**
   * 获取提前通知的分钟数
   * @param context 应用上下文
   * @returns 返回分钟数，如果未设置则返回默认值 (例如 5 分钟)
   */
  static async getAdvanceMinutes(context: common.UIAbilityContext): Promise<number> {
    const DEFAULT_MINUTES = 5; // 默认提前5分钟
    try {
      const preferences = await getPrefInstance(context);
      // ★★★ 修正 #3：明确指定返回类型为 number
      const minutes: number = await preferences.get(KEY_ADVANCE_MINUTES, DEFAULT_MINUTES) as number;
      return minutes;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[SettingsUtil] Failed to get advance minutes. Code: ${error.code}, message: ${error.message}`);
      return DEFAULT_MINUTES;
    }
  }
}