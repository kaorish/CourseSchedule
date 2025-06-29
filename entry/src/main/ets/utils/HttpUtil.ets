import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';

// ★★★ 1. 集中管理后端地址 ★★★
// 开发时用电脑的IP地址，手机和电脑需要在同一个局域网下
// 可以在CMD中用 ipconfig 命令查看你电脑的IPv4地址
const BASE_URL = 'http://192.168.230.147:8080/api'; // <<< 修改为你的电脑IP和端口

// ★★★ 2. 定义后端返回的数据结构，与后端的ResultUtil对应 ★★★
interface ApiResponse<T> {
  code: number;
  status: boolean;
  msg: string;
  data: T;
}

// ★★★ 3. 创建网络请求工具类 ★★★
class HttpUtil {

  // 通用的请求方法
  private async request<T>(url: string, method: http.RequestMethod, data?: object): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    try {
      let requestUrl = `${BASE_URL}${url}`;

      const options: http.HttpRequestOptions = {
        method: method,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: data ? JSON.stringify(data) : undefined,
        connectTimeout: 60000, // 连接超时时间
        readTimeout: 60000, // 读取超时时间
      };

      // 发起请求并等待响应
      const response = await httpRequest.request(requestUrl, options);

      if (response.responseCode === 200) {
        // 请求成功，解析JSON
        const resultStr = response.result.toString();
        const apiResponse: ApiResponse<T> = JSON.parse(resultStr);
        if (apiResponse.status) {
          // 后端返回业务成功
          return apiResponse;
        } else {
          // 后端返回业务失败
          // 我们可以直接抛出异常，让调用方去处理
          throw new Error(apiResponse.msg || '操作失败');
        }
      } else {
        // HTTP状态码非200，网络层面的失败
        throw new Error(`网络请求失败，状态码: ${response.responseCode}`);
      }
    } catch (err) {
      // 捕获所有异常，包括网络错误和JSON解析错误
      const error = err as BusinessError;
      console.error(`Request failed: ${error.message}, code: ${error.code}`);
      // 向上抛出一个更友好的错误信息
      throw new Error(error.message || '网络请求异常');
    } finally {
      // 销毁请求对象
      httpRequest.destroy();
    }
  }

  // ★★★ 4. 封装 GET, POST, PUT, DELETE 方法 ★★★

  // ★★★ 核心修正点：将params的类型从Record改为更通用的object ★★★
  public get<T>(url: string, params?: object): Promise<ApiResponse<T>> {
    if (params) {
      const query = Object.keys(params)
        .map(key => {
          // ★★★ 核心修正点：将 any 替换为明确的联合类型 ★★★
          const value = (params as Record<string, string | number | boolean>)[key];
          // 确保value不是undefined或null才拼接
          if (value !== undefined && value !== null) {
            return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
          }
          return '';
        })
        .filter(part => part !== '') // 过滤掉空字符串
        .join('&');

      if (query) {
        url = `${url}?${query}`;
      }
    }
    return this.request<T>(url, http.RequestMethod.GET);
  }

  public post<T>(url:string, data: object): Promise<ApiResponse<T>> {
    return this.request<T>(url, http.RequestMethod.POST, data);
  }

  public put<T>(url: string, data: object): Promise<ApiResponse<T>> {
    return this.request<T>(url, http.RequestMethod.PUT, data);
  }

  public delete<T>(url: string): Promise<ApiResponse<T>> {
    return this.request<T>(url, http.RequestMethod.DELETE);
  }
}

// 导出单例，确保整个App只有一个HttpUtil实例
export const httpUtil = new HttpUtil();