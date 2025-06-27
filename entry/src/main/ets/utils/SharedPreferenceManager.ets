// 文件路径: entry/src/main/ets/utils/SharedPreferenceManager.ets
import dataPreferences from '@ohos.data.preferences';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const PREF_FILE_NAME = 'course_app_settings';
const KEY_CURRENT_SEMESTER_ID = 'current_semester_id';

let prefInstance: dataPreferences.Preferences | null = null;

async function getPrefInstance(context: common.UIAbilityContext | common.FormExtensionContext): Promise<dataPreferences.Preferences> {
  if (prefInstance === null) {
    try {
      prefInstance = await dataPreferences.getPreferences(context, PREF_FILE_NAME);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[SharedPref] Failed to get preferences. Code: ${error.code}, msg: ${error.message}`);
      throw new Error(`Failed to get preferences instance: ${error.message}`);
    }
  }
  return prefInstance;
}

export class SharedPreferenceManager {
  /**
   * 保存当前学期ID
   */
  static async setCurrentSemesterId(context: common.UIAbilityContext, semesterId: number): Promise<void> {
    try {
      const pref = await getPrefInstance(context);
      await pref.put(KEY_CURRENT_SEMESTER_ID, semesterId);
      await pref.flush();
      console.log(`[SharedPref] Current semester ID saved: ${semesterId}`);
    } catch (error) {
      console.error(`[SharedPref] Failed to save semester ID: ${(error as Error).message}`);
    }
  }

  /**
   * 获取当前学期ID
   */
  static async getCurrentSemesterId(context: common.FormExtensionContext | common.UIAbilityContext): Promise<number> {
    const DEFAULT_SEMESTER_ID = 1; // 默认值为1
    try {
      const pref = await getPrefInstance(context);
      const semesterId = await pref.get(KEY_CURRENT_SEMESTER_ID, DEFAULT_SEMESTER_ID) as number;
      console.log(`[SharedPref] Got current semester ID: ${semesterId}`);
      return semesterId;
    } catch (error) {
      console.error(`[SharedPref] Failed to get semester ID: ${(error as Error).message}`);
      return DEFAULT_SEMESTER_ID;
    }
  }
}