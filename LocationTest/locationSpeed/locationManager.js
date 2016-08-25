//增加一个全局的定位对象locationManager；
window.locationManager={
  //定位成功的回调句柄，其中包括用户的经度、纬度、移动速度及其他
  successHandler: function(location){},
  //定位失败的回调句柄
  errorHandler: function(error){},
  //定位开始后，原生平台（ios、android）会通过原生代码调用handler回调
  start: function(){
    window.location.href='mobile-service://?action=location&command=start';
  },
  //定位停止（当页面不在需要定位功能时，请务必调用此函数关闭定位，保持电量）
  stop: function(){
    window.location.href='mobile-service://?action=location&command=stop';
  }
}
