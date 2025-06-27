// 文件路径: entry/src/main/ets/entryformability/EntryFormAbility.ets (最终正确版)
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want, common } from '@kit.AbilityKit';
import { httpUtil } from '../utils/HttpUtil';
import { TodayCourseResponse } from '../viewmodel/TodayScheduleViewModel';
import { SharedPreferenceManager } from '../utils/SharedPreferenceManager';
import { TimeSlot } from '../model/TimeSlot';

const TAG = '[EntryFormAbility]';

// ★★★ 核心修正 #1：定义一个接口来描述卡片数据的结构 ★★★
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

  private processRawCourses(courses: TodayCourseResponse[]): TodayCourseResponse[] {
    courses.forEach((course: TodayCourseResponse) => {
      course.specificStartTime = this.getTimeFromPeriod(course.startPeriod);
      course.specificEndTime = this.getEndTimeFromPeriod(course.endPeriod);
    });
    return courses;
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    console.info(`${TAG} === onAddForm START ===`);
    const formId = want?.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
    if (!formId) {
      console.error(`${TAG} Cannot get formId from want.`);
      return formBindingData.createFormBindingData({});
    }

    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const todayText = `今天 / ${weekdays[new Date().getDay()]}`;

    // ★★★ 核心修正 #2：使用接口 IWidgetData 来明确 initialData 的类型 ★★★
    const initialData: IWidgetData = {
      todayText: todayText,
      weekText: '',
      courses: [],
      isLoading: true,
      message: '正在加载...'
    };
    const formData = formBindingData.createFormBindingData(initialData);

    this.updateFormData(formId);

    console.info(`${TAG} === onAddForm END ===`);
    return formData;
  }

  private async updateFormData(formId: string) {
    console.info(`${TAG} --- updateFormData START for formId: ${formId} ---`);
    const context = this.context as common.FormExtensionContext;
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const todayText = `今天 / ${weekdays[new Date().getDay()]}`;

    let todayCourses: TodayCourseResponse[] = [];
    let finalMessage = '正在加载...';
    let finalIsLoading = true;

    try {
      const semesterId = await SharedPreferenceManager.getCurrentSemesterId(context);
      console.info(`${TAG} Current semesterId for widget: ${semesterId}`);

      const params = new GetTodayCourseParams();
      params.semesterId = semesterId;

      const response = await httpUtil.get<TodayCourseResponse[]>('/courses/today', params);
      console.info(`${TAG} Received raw response: ${JSON.stringify(response)}`);

      if (response.status && response.data) {
        console.info(`${TAG} Received ${response.data.length} courses.`);
        todayCourses = this.processRawCourses(response.data);
        if (todayCourses.length === 0) {
          finalMessage = '今日课程已上完';
        }
      } else {
        finalMessage = '数据加载失败';
        console.error(`${TAG} Response error: ${response.msg}`);
      }
    } catch (err) {
      finalMessage = '网络请求失败';
      console.error(`${TAG} Failed to fetch course data: ${(err as Error).message}`);
    }

    finalIsLoading = false;

    // ★★★ 核心修正 #3：使用接口 IWidgetData 来明确 finalUpdateData 的类型 ★★★
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
      await formProvider.updateForm(formId, formData);
      console.info(`${TAG} Form ${formId} updated successfully.`);
    } catch (updateError) {
      console.error(`${TAG} Failed to update form ${formId}: ${(updateError as Error).message}`);
    }

    console.info(`${TAG} --- updateFormData END for formId: ${formId} ---`);
  }

  onUpdateForm(formId: string) {
    console.info(`onUpdateForm, formId: ${formId}`);
    this.updateFormData(formId);
  }

  onRemoveForm(formId: string) {
    console.info(`onRemoveForm, formId: ${formId}`);
  }
}