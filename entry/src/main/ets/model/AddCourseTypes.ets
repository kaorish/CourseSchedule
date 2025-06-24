// 定义路由参数接口
export interface RouteParams {
  semesterId?: number;
  week?: number;
  shouldRefresh?: boolean;
}

// 定义星期选项接口
export interface DayOption {
  label: string;
  value: number;
}

// 预设颜色选项
export const COLOR_OPTIONS: string[] = [
  '#007DFF', '#E91E63', '#FF9800', '#4CAF50', 
  '#9C27B0', '#FF5722', '#607D8B', '#795548'
];

// 星期选项
export const DAY_OPTIONS: DayOption[] = [
  { label: '周一', value: 1 },
  { label: '周二', value: 2 },
  { label: '周三', value: 3 },
  { label: '周四', value: 4 },
  { label: '周五', value: 5 },
  { label: '周六', value: 6 },
  { label: '周日', value: 7 }
];