import { httpUtil } from '../utils/HttpUtil';
import { AddScheduleParams } from '../model/AddScheduleParams';
import { BusinessError } from '@ohos.base';

// 定义服务响应接口
export interface ServiceResponse {
  success: boolean;
  message: string;
}

// 定义表单验证结果接口
export interface ValidationResult {
  valid: boolean;
  message: string;
}

export class CourseService {
  static async saveCourse(params: AddScheduleParams): Promise<ServiceResponse> {
    try {
      console.log('开始保存课程，参数：', JSON.stringify(params));
      const response = await httpUtil.post<object>('/schedules', params);
      console.log('保存课程响应：', JSON.stringify(response));
      
      if (response.status) {
        const result: ServiceResponse = { success: true, message: '课程添加成功' };
        return result;
      } else {
        const result: ServiceResponse = { success: false, message: response.msg || '添加失败' };
        return result;
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('添加课程失败:', err);
      const result: ServiceResponse = { success: false, message: err.message || '网络请求失败' };
      return result;
    }
  }

  static validateCourseForm(params: AddScheduleParams): ValidationResult {
    if (params.courseName.trim() === '') {
      const result: ValidationResult = { valid: false, message: '请输入课程名称' };
      return result;
    }
    if (params.weeks.length === 0) {
      const result: ValidationResult = { valid: false, message: '请选择上课周次' };
      return result;
    }
    if (params.startPeriod > params.endPeriod) {
      const result: ValidationResult = { valid: false, message: '开始节次不能大于结束节次' };
      return result;
    }
    const result: ValidationResult = { valid: true, message: '' };
    return result;
  }
}