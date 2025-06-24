import { AddScheduleParams } from '../model/AddScheduleParams';

@Component
export struct BasicInfoForm {
  @Link courseParams: AddScheduleParams;

  build() {
    Column({ space: 12 }) {
      Text('基本信息')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      
      // 课程名称
      TextInput({ placeholder: '请输入课程名称', text: this.courseParams.courseName })
        .onChange((value: string) => {
          this.courseParams.courseName = value;
        })
      
      // 教师
      TextInput({ placeholder: '请输入教师姓名', text: this.courseParams.teacher })
        .onChange((value: string) => {
          this.courseParams.teacher = value;
        })
      
      // 地点
      TextInput({ placeholder: '请输入上课地点', text: this.courseParams.location })
        .onChange((value: string) => {
          this.courseParams.location = value;
        })
    }
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(8)
    .backgroundColor(Color.White)
  }
}