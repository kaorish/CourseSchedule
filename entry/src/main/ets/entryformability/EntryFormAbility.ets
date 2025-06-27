// 文件路径: entry/src/main/ets/entryformability/EntryFormAbility.ets (已修正)
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want, common } from '@kit.AbilityKit';
import { httpUtil } from '../utils/HttpUtil';
import { TodayCourseResponse } from '../viewmodel/TodayScheduleViewModel';
import { SharedPreferenceManager } from '../utils/SharedPreferenceManager';
import { TimeSlot } from '../model/TimeSlot'; // 导入TimeSlot模型

const TAG = '[EntryFormAbility]';

// 和 WidgetCard 中定义的数据结构保持一致
class WidgetData {
  todayText: string = '';
  weekText: string = ''; // 此字段可以后续扩展，例如显示当前是第几周
  courses: TodayCourseResponse[] = [];
  isLoading: boolean = true;
  message: string = '正在加载...';

  constructor(today: string, week: string = '') {
    this.todayText = today;
    this.weekText = week;
  }
}

class GetTodayCourseParams {
  semesterId: number = 1;
}

export default class EntryFormAbility extends FormExtensionAbility {

  // ★★★ 新增：从ViewModel中借鉴的时间转换逻辑 ★★★
  private timeSlotsDefinitions: TimeSlot[] = [
    new TimeSlot('1', '08:30', '09:15'), new TimeSlot('2', '09:20', '10:05'),
    new TimeSlot('3', '10:25', '11:10'), new TimeSlot('4', '11:15', '12:00'),
    new TimeSlot('5', '14:00', '14:45'), new TimeSlot('6', '14:50', '15:35'),
    new TimeSlot('7', '15:55', '16:40'), new TimeSlot('8', '16:45', '17:30'),
    new TimeSlot('9', '19:00', '19:45'), new TimeSlot('10', '19:50', '20:35')
  ];

  private getTimeFromPeriod(period: number): string {
    const slot = this.timeSlotsDefinitions.find(s => parseInt(s.label) === period);
    return slot ? slot.startTime : '';
  }

  private getEndTimeFromPeriod(period: number): string {
    const slot = this.timeSlotsDefinitions.find(s => parseInt(s.label) === period);
    return slot ? slot.endTime : '';
  }

  private processRawCourses(courses: TodayCourseResponse[]): TodayCourseResponse[] {
    courses.forEach((course: TodayCourseResponse) => {
      course.specificStartTime = this.getTimeFromPeriod(course.startPeriod);
      course.specificEndTime = this.getEndTimeFromPeriod(course.endPeriod);
    });
    return courses;
  }
  // ★★★ 时间转换逻辑结束 ★★★


  async onUpdateForm(formId: string) {
    console.info(`${TAG} onUpdateForm, formId: ${formId}`);
    await this.updateFormData(formId);
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    console.info(`${TAG} onAddForm, want: ${JSON.stringify(want)}`);
    const formId = want?.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
    if (!formId) {
      console.error(`${TAG} Cannot get formId from want.`);
      return formBindingData.createFormBindingData({});
    }

    const date = new Date();
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const todayText = `今天 / ${weekdays[date.getDay()]}`;

    const initialData = new WidgetData(todayText);
    const formData = formBindingData.createFormBindingData(initialData);

    this.updateFormData(formId);

    return formData;
  }

  private async updateFormData(formId: string) {
    const context = this.context as common.FormExtensionContext;

    const date = new Date();
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const todayText = `今天 / ${weekdays[date.getDay()]}`;
    const widgetData = new WidgetData(todayText);

    try {
      const semesterId = await SharedPreferenceManager.getCurrentSemesterId(context);
      console.info(`${TAG} Current semesterId for widget: ${semesterId}`);

      const params = new GetTodayCourseParams();
      params.semesterId = semesterId;

      console.info(`${TAG} Requesting today's courses...`);
      const response = await httpUtil.get<TodayCourseResponse[]>(`/courses/today`, params);

      if (response.status && response.data) {
        console.info(`${TAG} Received ${response.data.length} courses.`);
        // ★★★ 关键：在更新卡片前，处理数据，加上具体时间！ ★★★
        widgetData.courses = this.processRawCourses(response.data);
        if (response.data.length === 0) {
          widgetData.message = '今日课程已上完';
        }
      } else {
        widgetData.message = '数据加载失败';
        console.error(`${TAG} Response error: ${response.msg}`);
      }
    } catch (err) {
      const error = err as Error;
      widgetData.message = '网络请求失败';
      console.error(`${TAG} Failed to fetch course data: ${error.message}`);
      // 提示：请检查手机与电脑是否在同一局域网，以及电脑IP地址是否正确！
    } finally {
      widgetData.isLoading = false;
      try {
        const formData = formBindingData.createFormBindingData(widgetData);
        await formProvider.updateForm(formId, formData);
        console.info(`${TAG} Form ${formId} updated successfully.`);
      } catch (updateError) {
        console.error(`${TAG} Failed to update form ${formId}: ${(updateError as Error).message}`);
      }
    }
  }

  onRemoveForm(formId: string) {
    console.info(`${TAG} onRemoveForm, formId: ${formId}`);
  }
}