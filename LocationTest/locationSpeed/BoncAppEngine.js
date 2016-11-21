
//用一个iframe向原生代码发送urlScheme
function callObject(uri){
  var BAEIframe = document.createElement('iframe');
        BAEIframe.style.display = 'none';
        BAEIframe.src = uri;
        document.documentElement.appendChild(BAEIframe);
        setTimeout(function() { document.documentElement.removeChild(BAEIframe) }, 0)
};

boncAppEngine ={
  //设备对象
  device: {
    //原生获取设备信息成功的回调句柄，其中包括用户的经度、纬度、移动速度及其他
    successHandler: function(deviceInfo){},
    //原生获取设备信息失败的回调句柄
    errorHandler: function(error){},
    //js调用获取设备信息
    getDeviceInfo: function(success,error){
      this.successHandler=success;
      this.errorHandler=error;
      var uri='mobile-service://?object=device&command=getDeviceInfo';
      callObject(uri);
    },
    //js调用设备震动
    vibrate: function(){
      var uri='mobile-service://?object=device&command=vibrate'
      callObject(uri);
    }
  },
  //定位对象locationManager；
  locationManager: {
    //原生定位成功的回调句柄，其中包括用户的经度、纬度、移动速度及其他
    successHandler: function(location){},
    //原生定位失败的回调句柄
    errorHandler: function(error){},
    //js调用开始定位，原生平台（ios、android）会通过原生代码调用handler回调
    start: function(success,error){
      this.successHandler=success.bind(this);
      this.errorHandler=error.bind(this);
      var uri='mobile-service://?object=locationManager&command=start';
      callObject(uri);
    },
    //js调用停止定位（当页面不在需要定位功能时，请务必调用此函数关闭定位，保持电量）
    stop: function(){
      var uri='mobile-service://?object=locationManager&command=stop';
      callObject(uri);
    }
  },
  //加速度计
  accelerometer: {
    //原生回调返回加速度计信息的句柄
    successHandler: function(location){},
    //原生回调错误信息的句柄
    errorHandler: function(error){},
    //js调用开始采集加速度信息
    start: function(success,error){
      this.successHandler=successHandler;
      this.errorHandler=error;
      var uri='mobile-service://?object=accelerometer&command=start';
      callObject(uri);
    },
    //js调用停止采集加速度信息
    stop: function(){
      var uri='mobile-service://?object=accelerometer&command=stop';
      callObject(uri);
    }
  },
  //相机对象camera
  camera: {
    //原生拍照成功的回调句柄，其中包括照片数据Base64编码的字符串，以及照片的类型；
    successHandler: function(imageInfo){},
    //原生拍照发生错误的回调句柄
    errorHandler: function(errror){},
    //原生用户取消拍照的回调句柄
    cancelHandler: function(){},
    //js调用拍照
    takePhoto: function(success,cancle,error){
      this.successHandler=success;
      this.cancleHandler=cancle;
      this.errorHandler=error;
      var uri='mobile-service://?object=camera&command=takePhoto';
      callObject(uri);
    }
  },
  //手机通讯录对象contacts
  contacts: {
    //原生访问联系人成功的回调句柄
    successHandler: function(conatactsInfo){},
    //原生访问联系人出错的回到句柄
    errorHandler: function(errror){},
    //js调用获取联系人
    getAllContacts: function(success,error){
      this.success=success;
      this.error=error;
      var uri='mobile-service://?object=contacts&command=getAllContacts';
    }
  },
  //二维码扫描器对象codeScanner；
  codeScanner: {
    //原生扫描成功的回调句柄，其中包括用户的经度、纬度、移动速度及其他
    successHandler: function(codeInfo){},
    //原生扫描失败的回调句柄
    errorHandler: function(error){},
    //原生用户取消扫描操作的回调句柄
    cancleHandler: function(){},
    //js调用扫描
    scan: function(success,cancle,error){
      this.successHandler=success;
      this.cancleHandler=cancle;
      this.errorHandler=error;
      var uri='mobile-service://?object=codeScanner&command=scan';
      callObject(uri);
    }
  }
}
