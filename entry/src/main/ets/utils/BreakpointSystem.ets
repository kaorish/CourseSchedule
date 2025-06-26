// 文件路径: entry/src/main/ets/utils/BreakpointSystem.ets
// (请完全替换此文件内容)

import { hilog } from '@kit.PerformanceAnalysisKit';
import mediaQuery from '@ohos.mediaquery';

const DOMAIN = 0x0000;
const TAG = 'BreakpointSystem';

// 屏幕尺寸定义 (单位: vp)
export enum BreakpointConstants {
  BREAKPOINT_SM = 320,
  BREAKPOINT_MD = 600,
  BREAKPOINT_LG = 840
}

// 设备类型枚举
export enum DeviceType {
  PHONE = 0,
  TABLET,
  DESKTOP
}

// 创建屏幕断点系统类
export class BreakpointSystem {
  private smListener: mediaQuery.MediaQueryListener;
  private mdListener: mediaQuery.MediaQueryListener;
  private lgListener: mediaQuery.MediaQueryListener;

  // 当前设备类型
  public currentDeviceType: DeviceType = DeviceType.PHONE;

  constructor() {
    this.smListener = mediaQuery.matchMediaSync(`(min-width: ${BreakpointConstants.BREAKPOINT_SM}vp)`);
    this.mdListener = mediaQuery.matchMediaSync(`(min-width: ${BreakpointConstants.BREAKPOINT_MD}vp)`);
    this.lgListener = mediaQuery.matchMediaSync(`(min-width: ${BreakpointConstants.BREAKPOINT_LG}vp)`);

    // 初始化时就判断一次设备类型
    this.currentDeviceType = this.checkDeviceType();
  }

  // 统一的检查函数，保证从大到小的判断顺序
  private checkDeviceType(): DeviceType {
    if (this.lgListener.matches) {
      hilog.info(DOMAIN, TAG, 'Large screen matched. Device: DESKTOP');
      return DeviceType.DESKTOP;
    }
    if (this.mdListener.matches) {
      hilog.info(DOMAIN, TAG, 'Medium screen matched. Device: TABLET');
      return DeviceType.TABLET;
    }
    hilog.info(DOMAIN, TAG, 'Small screen matched. Device: PHONE');
    return DeviceType.PHONE;
  }

  // 注册屏幕变化回调
  public register(callback: (deviceType: DeviceType) => void): void {
    // 让所有监听器都调用同一个检查函数
    const mediaQueryCallback = () => {
      this.currentDeviceType = this.checkDeviceType();
      callback(this.currentDeviceType);
    }

    this.smListener.on('change', mediaQueryCallback);
    this.mdListener.on('change', mediaQueryCallback);
    this.lgListener.on('change', mediaQueryCallback);
  }

  // 取消注册所有监听
  public unregister(): void {
    this.smListener.off('change');
    this.mdListener.off('change');
    this.lgListener.off('change');
  }

  // 根据设备类型获取不同布局参数
  public getLayoutParam<T>(phone: T, tablet: T, desktop: T): T {
    switch (this.currentDeviceType) {
      case DeviceType.PHONE:
        return phone;
      case DeviceType.TABLET:
        return tablet;
      case DeviceType.DESKTOP:
        return desktop;
      default:
        return phone;
    }
  }
}