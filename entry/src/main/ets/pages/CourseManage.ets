import router from '@ohos.router'
import { httpUtil } from '../utils/HttpUtil'
import { ScheduleManageVO, GetScheduleListParams } from '../model/ScheduleModels'
import { AppSettings } from '../common/AppSettings'

@Entry
@Component
struct CourseManage {
  @State courses: ScheduleManageVO[] = []
  @State loading: boolean = false
  @State currentSemesterId: number | undefined = AppStorage.Get<number>(AppSettings.CURRENT_SEMESTER_ID_KEY) // 可以从全局状态或参数获取

  aboutToAppear() {
    this.loadCourses()
  }

  async loadCourses() {
    this.loading = true
    try {
      const params = new GetScheduleListParams()
      params.semesterId = this.currentSemesterId
      
      // 修改这里：正确处理ApiResponse<ScheduleManageVO[]>响应
      const response = await httpUtil.get<ScheduleManageVO[]>('/schedules', params)
      // response是ApiResponse<ScheduleManageVO[]>类型，需要访问data属性
      this.courses = response.data || []
      
    } catch (error) {
      console.error('加载课程失败:', error)
      this.courses = []
    } finally {
      this.loading = false
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Image($r('app.media.back'))
            .width(24)
            .height(24)
            .fillColor('#000000')
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back()
        })

        Text('课程管理')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位，保持标题居中
        Row()
          .width(48)
          .height(48)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      if (this.loading) {
        // 加载状态
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.courses.length === 0) {
        // 空状态
        Column() {
          Text('暂无课程')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 课程列表
        List() {
          ForEach(this.courses, (course: ScheduleManageVO, index: number) => {
            ListItem() {
              this.CourseItem(course)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  CourseItem(course: ScheduleManageVO) {
    Row() {
      // 课程颜色指示器
      Column()
        .width(4)
        .height(60)
        .backgroundColor(course.color || '#007AFF')
        .borderRadius(2)
        .margin({ right: 12 })

      Column() {
        Text(course.courseName || '课程名称')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(`${course.teacher || '教师'} | ${course.location || '教室'}`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 4 })
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(`${course.dayOfWeekText || ''} ${course.timeText || ''} ${course.weeksText || ''}`)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button('编辑')
        .fontSize(14)
        .fontColor('#007AFF')
        .backgroundColor(Color.Transparent)
        .border({
          width: 1,
          color: '#007AFF',
          radius: 4
        })
        .padding({ left: 16, right: 16, top: 6, bottom: 6 })
        .onClick(() => {
          this.editCourse(course)
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 12 })
  }

  editCourse(course: ScheduleManageVO) {
    router.pushUrl({
      url: 'pages/EditCourse',
      params: {
        scheduleId: course.scheduleId,
        isEdit: true
      }
    })
  }
}