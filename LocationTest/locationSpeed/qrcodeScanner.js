//增加一个全局的二维码扫描对象qrcodeScanner；
window.qrcodeScanner={
  //定位成功的回调句柄，其中包括用户的经度、纬度、移动速度及其他
  successHandler: function(infomation){},
  //定位失败的回调句柄
  errorHandler: function(error){},
  //定位开始后，原生平台（ios、android）会通过原生代码调用handler回调
  scan: function(){
    window.location.href='mobile-service://?action=scanQRCode&command=scan';
  }
}
