// 文件路径: entry/src/main/ets/entryformability/EntryFormAbility.ets (最终版)
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want, common } from '@kit.AbilityKit';
import { httpUtil } from '../utils/HttpUtil';
import { TodayCourseResponse } from '../viewmodel/TodayScheduleViewModel';
import { SharedPreferenceManager } from '../utils/SharedPreferenceManager';
import { TimeSlot } from '../model/TimeSlot';

const TAG = '[EntryFormAbility]';

// 定义卡片数据的接口，确保类型安全
interface IWidgetData {
  todayText: string;
  weekText: string;
  courses: TodayCourseResponse[];
  isLoading: boolean;
  message: string;
}

class GetTodayCourseParams {
  semesterId: number = 1;
}

export default class EntryFormAbility extends FormExtensionAbility {
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

  // 为课程数据补充具体时间
  private processRawCourses(courses: TodayCourseResponse[]): TodayCourseResponse[] {
    courses.forEach((course: TodayCourseResponse) => {
      course.specificStartTime = this.getTimeFromPeriod(course.startPeriod);
      course.specificEndTime = this.getEndTimeFromPeriod(course.endPeriod);
    });
    return courses;
  }

  // 当卡片第一次被添加到桌面时调用
  onAddForm(want: Want): formBindingData.FormBindingData {
    console.info(`${TAG} === onAddForm START ===`);
    const formId = want?.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
    if (!formId) {
      console.error(`${TAG} Cannot get formId from want.`);
      return formBindingData.createFormBindingData({});
    }

    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const todayText = `今天 / ${weekdays[new Date().getDay()]}`;

    // 定义卡片的初始数据，此时显示“正在加载”
    const initialData: IWidgetData = {
      todayText: todayText,
      weekText: '',
      courses: [],
      isLoading: true, // 初始状态为加载中
      message: '正在加载...'
    };
    const formData = formBindingData.createFormBindingData(initialData);

    // 立即触发一次异步数据更新
    this.updateFormData(formId);

    console.info(`${TAG} === onAddForm END (returning initial data) ===`);
    return formData;
  }

  // 核心的异步数据更新方法
  private async updateFormData(formId: string) {
    console.info(`${TAG} --- updateFormData START for formId: ${formId} ---`);
    const context = this.context as common.FormExtensionContext;
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const todayText = `今天 / ${weekdays[new Date().getDay()]}`;

    let todayCourses: TodayCourseResponse[] = [];
    let finalMessage = '';
    let finalIsLoading = true;

    try {
      const semesterId = await SharedPreferenceManager.getCurrentSemesterId(context);
      console.info(`${TAG} Current semesterId for widget: ${semesterId}`);

      const params = new GetTodayCourseParams();
      params.semesterId = semesterId;

      const response = await httpUtil.get<TodayCourseResponse[]>('/courses/today', params);

      if (response.status && response.data) {
        todayCourses = this.processRawCourses(response.data);
        if (todayCourses.length === 0) {
          finalMessage = '今日课程已上完';
        } else {
          finalMessage = ''; // 有课程时，不需要显示消息
        }
      } else {
        finalMessage = '数据加载失败';
        console.error(`${TAG} Response error: ${response.msg}`);
      }
    } catch (err) {
      finalMessage = '网络请求失败';
      console.error(`${TAG} Failed to fetch course data: ${(err as Error).message}`);
    }

    // 数据处理完成，设置加载状态为 false
    finalIsLoading = false;

    // 准备最终要更新到卡片的数据
    const finalUpdateData: IWidgetData = {
      todayText: todayText,
      weekText: '',
      courses: todayCourses,
      isLoading: finalIsLoading,
      message: finalMessage
    };

    try {
      console.info(`${TAG} Updating form with final data: ${JSON.stringify(finalUpdateData)}`);
      const formData = formBindingData.createFormBindingData(finalUpdateData);
      // 使用 formProvider 更新卡片
      await formProvider.updateForm(formId, formData);
      console.info(`${TAG} Form ${formId} updated successfully.`);
    } catch (updateError) {
      console.error(`${TAG} Failed to update form ${formId}: ${(updateError as Error).message}`);
    }

    console.info(`${TAG} --- updateFormData END for formId: ${formId} ---`);
  }

  // onUpdateForm 和 onRemoveForm 由系统定时或在特定事件触发
  onUpdateForm(formId: string) {
    console.info(`${TAG} onUpdateForm, formId: ${formId}`);
    this.updateFormData(formId);
  }

  onRemoveForm(formId: string) {
    console.info(`${TAG} onRemoveForm, formId: ${formId}`);
  }
}