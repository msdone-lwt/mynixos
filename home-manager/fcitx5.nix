# home-manager/fcitx5.nix
{
  pkgs,
  ...
}:

{
  xdg.configFile = {
    "fcitx5/profile" = {
      force = true;
      text = ''
        [Groups/0]
        # Group Name
        Name=默认
        # Layout
        Default Layout=us
        # Default Input Method
        DefaultIM=shuangpin
        
        [Groups/0/Items/0]
                # Name
        Name=keyboard-us
        # Layout
        Layout=
        
        [Groups/0/Items/1]
        # Name
        Name=shuangpin
        # Layout
        Layout=
        
        [GroupOrder]
        0=默认
      '';
    };

    "fcitx5/conf/pinyin.conf" = {
      force = true;
      text = ''
        # 双拼方案
        ShuangpinProfile=Xiaohe
        # 显示当前双拼模式
        ShowShuangpinMode=False
      '';
    };

    "fcitx5/conf/classicui.conf" = {
      force = true;
      text = ''
        # 主题
        Theme=Material-Color-black
        # 深色主题
        DarkTheme=Material-Color-black
        # 跟随系统浅色/深色设置
        UseDarkTheme=true
	# 字体
        Font="Sans 12"
        # 菜单字体
        MenuFont="Sans 12"
        # 托盘字体
        TrayFont="Sans Bold 12"
      '';
    };

    "fcitx5/config" = {
      force = true;
      text = ''
        [Hotkey/TriggerKeys]
        0=Shift+Shift_L
        1=Zenkaku_Hankaku
        2=Hangul
      '';
    };
  };
}
