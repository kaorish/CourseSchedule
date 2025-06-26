import router from '@ohos.router';
import { AddScheduleParams } from '../model/AddScheduleParams';
import { RouteParams } from '../model/AddCourseTypes';
import { BasicInfoForm } from '../components/BasicInfoForm';
import { TimeInfoForm } from '../components/TimeInfoForm';
import { WeekSelectionForm } from '../components/WeekSelectionForm';
import { ColorSelectionForm } from '../components/ColorSelectionForm';
import { CourseService, ServiceResponse, ValidationResult } from '../service/CourseService';

@Entry
@Component
struct AddCourse {
  @State courseParams: AddScheduleParams = new AddScheduleParams();
  @State isLoading: boolean = false;
  @State selectedWeeks: Set<number> = new Set<number>();

  aboutToAppear(): void {
    const params = router.getParams() as RouteParams;
    if (params) {
      this.courseParams.semesterId = params.semesterId || 1;
      const currentWeek = params.week;
      if (currentWeek && currentWeek > 0) {
        this.selectedWeeks.add(currentWeek);
        this.courseParams.weeks = [currentWeek];
      }
    }
  }

  build() {
    Column() {
      this.buildTopBar()

      Scroll() {
        Column({ space: 16 }) {
          BasicInfoForm({ courseParams: $courseParams })
          TimeInfoForm({ courseParams: $courseParams })
          WeekSelectionForm({
            courseParams: $courseParams,
            selectedWeeks: $selectedWeeks
          })
          ColorSelectionForm({ courseParams: $courseParams })
        }
        .padding(16)
      }
      .layoutWeight(1)

      this.buildBottomButtons()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildTopBar() {
    Row() {
      Button('取消')
        .fontColor('#007DFF')
        .backgroundColor(Color.Transparent)
        .onClick(() => router.back())

      Blank()

      Text('添加课程')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)

      Blank()

      Button('保存')
        .fontColor(this.isLoading ? Color.Gray : '#007DFF')
        .backgroundColor(Color.Transparent)
        .enabled(!this.isLoading)
        .onClick(() => this.handleSaveCourse())
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }

  @Builder
  buildBottomButtons() {
    Row({ space: 16 }) {
      Button('取消')
        .layoutWeight(1)
        .height(48)
        .fontColor('#666')
        .backgroundColor('#F0F0F0')
        .onClick(() => router.back())

      Button(this.isLoading ? '保存中...' : '保存课程')
        .layoutWeight(1)
        .height(48)
        .fontColor(Color.White)
        .backgroundColor('#007DFF')
        .enabled(!this.isLoading)
        .onClick(() => this.handleSaveCourse())
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
  }

  private async handleSaveCourse(): Promise<void> {
    const validation: ValidationResult = CourseService.validateCourseForm(this.courseParams);
    if (!validation.valid) {
      this.showToast(validation.message);
      return;
    }

    this.isLoading = true;

    const result: ServiceResponse = await CourseService.saveCourse(this.courseParams);

    if (result.success) {
      AlertDialog.show({
        title: '成功',
        message: result.message,
        confirm: {
          value: '确定',
          action: () => {
            router.replaceUrl({
              url: 'pages/MainPage',
              params: {
                shouldRefresh: true,
                refreshTime: Date.now()
              }
            });
          }
        }
      });
    } else {
      this.showToast(result.message);
    }

    this.isLoading = false;
  }

  private showToast(message: string): void {
    AlertDialog.show({
      title: '提示',
      message: message,
      confirm: {
        value: '确定',
        action: () => console.log('用户确认提示')
      }
    });
  }
}