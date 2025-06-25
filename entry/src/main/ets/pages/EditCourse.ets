import router from '@ohos.router'
import { httpUtil } from '../utils/HttpUtil'
import { ScheduleDetailVO, UpdateScheduleParams } from '../model/ScheduleModels'

@Entry
@Component
struct EditCourse {
  @State courseData: ScheduleDetailVO = new ScheduleDetailVO()
  @State scheduleId: number = 0
  @State loading: boolean = false
  @State saving: boolean = false
  
  // 添加独立的状态变量来强制界面更新
  @State selectedWeekDay: string = '请选择'
  @State selectedStartPeriod: number = 1
  @State selectedEndPeriod: number = 1
  @State selectedWeeks: number[] = []
  @State selectedColor: string = '#FF6B6B'

  // 星期选项
  private weekDayOptions: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
  
  // 颜色选项
  private colorOptions: string[] = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', 
    '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F'
  ]

  // 预定义周次数组
  private weekNumbers: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]

  // 节次选项
  private periodOptions: string[] = ['第1节', '第2节', '第3节', '第4节', '第5节', '第6节', '第7节', '第8节', '第9节', '第10节', '第11节', '第12节']

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params && params.scheduleId) {
      this.scheduleId = params.scheduleId as number
      this.loadCourseDetail()
    }
  }

  async loadCourseDetail() {
    this.loading = true
    try {
      const response = await httpUtil.get<ScheduleDetailVO>(`/schedules/${this.scheduleId}`)
      this.courseData = response.data || new ScheduleDetailVO()
      
      // 同步状态变量
      this.syncStateVariables()
      
    } catch (error) {
      console.error('加载课程详情失败:', error)
    } finally {
      this.loading = false
    }
  }

  // 同步所有状态变量 - 修复索引问题
  private syncStateVariables() {
    // 修复数组索引问题：dayOfWeek是1-7，数组索引是0-6
    this.selectedWeekDay = (this.courseData.dayOfWeek >= 1 && this.courseData.dayOfWeek <= 7) 
      ? this.weekDayOptions[this.courseData.dayOfWeek - 1] 
      : '请选择'
    this.selectedStartPeriod = this.courseData.startPeriod || 1
    this.selectedEndPeriod = this.courseData.endPeriod || 1
    this.selectedWeeks = [...this.courseData.weeks]
    this.selectedColor = this.courseData.color || '#FF6B6B'
    
    console.log('同步状态变量:', {
      dayOfWeek: this.courseData.dayOfWeek,
      selectedWeekDay: this.selectedWeekDay,
      startPeriod: this.selectedStartPeriod,
      endPeriod: this.selectedEndPeriod,
      weeks: this.selectedWeeks,
      color: this.selectedColor
    })
  }

  async saveCourse() {
    if (!this.validateForm()) {
      return
    }

    this.saving = true
    try {
      const updateParams = new UpdateScheduleParams()
      updateParams.courseName = this.courseData.courseName
      updateParams.teacher = this.courseData.teacher
      updateParams.color = this.selectedColor
      updateParams.location = this.courseData.location
      updateParams.dayOfWeek = this.courseData.dayOfWeek
      updateParams.startPeriod = this.selectedStartPeriod
      updateParams.endPeriod = this.selectedEndPeriod
      updateParams.weeks = [...this.selectedWeeks]

      await httpUtil.put<object>(`/schedules/${this.scheduleId}`, updateParams)
      
      this.showToast('保存成功')
      setTimeout(() => {
        router.back()
      }, 1000)
      
    } catch (error) {
      console.error('保存课程失败:', error)
      this.showToast('保存失败')
    } finally {
      this.saving = false
    }
  }

  async deleteCourse() {
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这门课程吗？删除后无法恢复。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#FF3B30',
        action: async () => {
          this.saving = true
          try {
            await httpUtil.delete<object>(`/schedules/${this.scheduleId}`)
            this.showToast('删除成功')
            setTimeout(() => {
              router.back()
            }, 1000)
          } catch (error) {
            console.error('删除课程失败:', error)
            this.showToast('删除失败')
          } finally {
            this.saving = false
          }
        }
      }
    })
  }

  validateForm(): boolean {
    if (!this.courseData.courseName.trim()) {
      this.showToast('请输入课程名称')
      return false
    }
    if (!this.courseData.teacher.trim()) {
      this.showToast('请输入教师姓名')
      return false
    }
    if (!this.courseData.location.trim()) {
      this.showToast('请输入上课地点')
      return false
    }
    if (this.courseData.dayOfWeek < 1 || this.courseData.dayOfWeek > 7) {
      this.showToast('请选择星期')
      return false
    }
    if (this.selectedStartPeriod < 1 || this.selectedEndPeriod < 1) {
      this.showToast('请设置上课时间')
      return false
    }
    if (this.selectedStartPeriod > this.selectedEndPeriod) {
      this.showToast('开始节次不能大于结束节次')
      return false
    }
    if (this.selectedWeeks.length === 0) {
      this.showToast('请选择上课周次')
      return false
    }
    return true
  }

  showToast(message: string) {
    AlertDialog.show({
      message: message,
      primaryButton: {
        value: '确定',
        action: () => {}
      }
    })
  }

  // 修复星期选择器
  showWeekPicker() {
    const currentSelected = this.courseData.dayOfWeek > 0 ? this.courseData.dayOfWeek - 1 : 0
    
    console.log('打开星期选择器:', {
      dayOfWeek: this.courseData.dayOfWeek,
      currentSelected: currentSelected,
      options: this.weekDayOptions
    })
    
    TextPickerDialog.show({
      range: this.weekDayOptions,
      selected: currentSelected,
      onAccept: (value: TextPickerResult) => {
        const selectedIndex = Number(value.index)
        this.courseData.dayOfWeek = selectedIndex + 1
        this.selectedWeekDay = this.weekDayOptions[selectedIndex] // 直接使用选中的索引
        
        console.log('星期选择结果:', {
          selectedIndex: selectedIndex,
          dayOfWeek: this.courseData.dayOfWeek,
          selectedWeekDay: this.selectedWeekDay
        })
      },
      onCancel: () => {
        console.log('取消选择星期')
      }
    })
  }

  // 节次选择器
  showPeriodPicker(isStart: boolean) {
    const currentValue = isStart ? this.selectedStartPeriod - 1 : this.selectedEndPeriod - 1
    
    TextPickerDialog.show({
      range: this.periodOptions,
      selected: currentValue >= 0 ? currentValue : 0,
      onAccept: (value: TextPickerResult) => {
        const selectedIndex = Number(value.index)
        const selectedPeriod = selectedIndex + 1
        
        if (isStart) {
          this.selectedStartPeriod = selectedPeriod
          this.courseData.startPeriod = selectedPeriod
          // 如果开始节次大于结束节次，自动调整结束节次
          if (this.selectedStartPeriod > this.selectedEndPeriod) {
            this.selectedEndPeriod = this.selectedStartPeriod
            this.courseData.endPeriod = this.selectedStartPeriod
          }
        } else {
          this.selectedEndPeriod = selectedPeriod
          this.courseData.endPeriod = selectedPeriod
          // 如果结束节次小于开始节次，自动调整开始节次
          if (this.selectedEndPeriod < this.selectedStartPeriod) {
            this.selectedStartPeriod = this.selectedEndPeriod
            this.courseData.startPeriod = this.selectedEndPeriod
          }
        }
        
        console.log('选择的节次:', selectedPeriod, '开始节次:', this.selectedStartPeriod, '结束节次:', this.selectedEndPeriod)
      },
      onCancel: () => {
        console.log('取消选择节次')
      }
    })
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

        Text('编辑课程')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Button('删除')
          .fontSize(16)
          .fontColor('#FF3B30')
          .backgroundColor(Color.Transparent)
          .enabled(!this.saving)
          .onClick(() => {
            this.deleteCourse()
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      if (this.loading) {
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
      } else {
        Scroll() {
          Column({ space: 16 }) {
            // 基本信息
            Column() {
              Text('基本信息')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .margin({ bottom: 12 })
              
              this.InputField('课程名称', this.courseData.courseName, (value: string) => {
                this.courseData.courseName = value
              })
              
              this.InputField('教师姓名', this.courseData.teacher, (value: string) => {
                this.courseData.teacher = value
              })
              
              this.InputField('上课地点', this.courseData.location, (value: string) => {
                this.courseData.location = value
              })
            }
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .padding(16)

            // 时间设置
            Column() {
              Text('时间设置')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .margin({ bottom: 12 })
              
              // 使用独立的状态变量
              this.SelectField('星期', this.selectedWeekDay, () => {
                this.showWeekPicker()
              })
              
              this.TimeRangeField()
            }
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .padding(16)

            // 周次选择
            Column() {
              Text('周次选择')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .margin({ bottom: 12 })
              
              this.WeekSelector()
            }
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .padding(16)

            // 颜色选择
            Column() {
              Text('课程颜色')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .margin({ bottom: 12 })
              
              this.ColorSelector()
            }
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .padding(16)

            // 保存按钮
            Button(this.saving ? '保存中...' : '保存')
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .backgroundColor('#007AFF')
              .borderRadius(8)
              .margin({ top: 16, bottom: 32 })
              .enabled(!this.saving)
              .onClick(() => {
                this.saveCourse()
              })
          }
          .padding(16)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  InputField(label: string, value: string, onChange: (value: string) => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .width(80)
      
      TextInput({ text: value })
        .layoutWeight(1)
        .onChange(onChange)
        .backgroundColor('#F8F8F8')
        .border({ radius: 4 })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  SelectField(label: string, value: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .width(80)
      
      Row() {
        Text(value)
          .fontSize(14)
          .fontColor(value.includes('请选择') ? '#999999' : '#333333')
          .layoutWeight(1)
      }
      .layoutWeight(1)
      .height(40)
      .backgroundColor('#F8F8F8')
      .borderRadius(4)
      .padding({ left: 12, right: 12 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .onClick(onClick)
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  TimeRangeField() {
    Row() {
      Text('节次')
        .fontSize(14)
        .width(80)
      
      Row() {
        Text(`第${this.selectedStartPeriod}节`)
          .fontSize(14)
          .backgroundColor('#F8F8F8')
          .padding(8)
          .borderRadius(4)
          .onClick(() => {
            this.showPeriodPicker(true)
          })
        
        Text(' - ')
          .margin({ left: 8, right: 8 })
        
        Text(`第${this.selectedEndPeriod}节`)
          .fontSize(14)
          .backgroundColor('#F8F8F8')
          .padding(8)
          .borderRadius(4)
          .onClick(() => {
            this.showPeriodPicker(false)
          })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  WeekSelector() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
      ForEach(this.weekNumbers, (week: number) => {
        Text(week.toString())
          .fontSize(14)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.selectedWeeks.includes(week) ? '#007AFF' : '#F8F8F8')
          .fontColor(this.selectedWeeks.includes(week) ? Color.White : '#333333')
          .borderRadius(4)
          .margin({ right: 8, bottom: 8 })
          .onClick(() => {
            const index = this.selectedWeeks.indexOf(week)
            if (index > -1) {
              this.selectedWeeks.splice(index, 1)
            } else {
              this.selectedWeeks.push(week)
            }
            this.selectedWeeks.sort((a, b) => a - b)
            // 同步到courseData
            this.courseData.weeks = [...this.selectedWeeks]
            
            console.log('周次选择更新:', this.selectedWeeks)
          })
      }, (week: number) => week.toString())
    }
  }

  @Builder
  ColorSelector() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
      ForEach(this.colorOptions, (color: string) => {
        Circle({ width: 40, height: 40 })
          .fill(color)
          .stroke(this.selectedColor === color ? '#333333' : Color.Transparent)
          .strokeWidth(2)
          .margin({ right: 12, bottom: 12 })
          .onClick(() => {
            this.selectedColor = color
            this.courseData.color = color
            
            console.log('颜色选择更新:', color)
          })
      }, (color: string) => color)
    }
  }
}