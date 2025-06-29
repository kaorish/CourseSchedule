import { TodayCourseResponse } from '../../viewmodel/TodayScheduleViewModel';

const TAG = '[WidgetCard]';

@Entry
@Component
struct WidgetCard {
  @LocalStorageProp('todayText') todayText: string = '今天';
  @LocalStorageProp('weekText') weekText: string = '';
  @LocalStorageProp('courses') courses: TodayCourseResponse[] = [];
  @LocalStorageProp('isLoading') isLoading: boolean = true;
  @LocalStorageProp('message') message: string = '正在加载...';

  aboutToAppear() {
    console.info(`${TAG} === aboutToAppear ===`);
    console.info(`${TAG} Initial Data Check - isLoading: ${this.isLoading}, message: ${this.message}`);
    console.info(`${TAG} Courses count: ${this.courses.length}`);
  }

  build() {
    FormLink({
      action: 'router',
      bundleName: 'com.sunhao.myapplication',
      abilityName: 'EntryAbility',
    }) {
      Column() {
        Row() {
          Text(this.todayText)
            .fontSize(14)
            .fontColor('#333333')
          Blank()
          Text(this.weekText)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')
        .padding({ top: 12, left: 16, right: 16, bottom: 8 })

        Column() {
          if (this.isLoading === true) {
            Text(this.message)
              .fontSize(16)
              .fontColor('#999999')
          } else if (this.courses && this.courses.length > 0) {
            this.CourseList(this.courses)
          } else {
            Text(this.message || '今日无课程')
              .fontSize(16)
              .fontColor('#999999')
          }
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ left: 16, right: 16, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
      .borderRadius(24)
      .onClick(()=>{
        postCardAction(this,{
          action: 'router',
          abilityName: 'EntryAbility',
          params:''
        })
      })
    }
  }

  @Builder
  CourseList(courses: TodayCourseResponse[]) {
    List({ space: 8 }) {
      ForEach(courses, (course: TodayCourseResponse) => {
        ListItem() {
          this.CourseItem(course)
        }
      }, (course: TodayCourseResponse) => course.scheduleId.toString())
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CourseItem(course: TodayCourseResponse) {
    Row({ space: 8 }) {
      Divider().vertical(true).width(4).height(40).backgroundColor(course.color).borderRadius(2)
      Column({ space: 2 }) {
        Text(course.name).fontSize(15).fontWeight(FontWeight.Bold).fontColor('#000000').maxLines(1).textOverflow({overflow: TextOverflow.Ellipsis})
        Text(`@ ${course.location}`).fontSize(12).fontColor('#666666').maxLines(1).textOverflow({overflow: TextOverflow.Ellipsis})
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1).padding({left: 4})
      Column({ space: 4 }) {
        Text(course.specificStartTime ?? '').fontSize(12).fontColor('#333333')
        Text(course.specificEndTime ?? '').fontSize(12).fontColor('#333333')
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%').padding({left:8, right: 12, top: 10, bottom: 10}).borderRadius(12).backgroundColor('#F7F7F7')
  }
}