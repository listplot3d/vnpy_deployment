#!/usr/bin/env bash

echo '
+ 如何使用: 将本文件命名为env.sh，然后用root用户运行"bash env.sh"
+ 测试通过的环境: 阿里云ECS + Ubuntu 18.04 + root用户
+ 2019.05.18 by 胖子笑
'

# ‘********** 1.下载各种包 **********'
# ’VNPY (注意:若网速慢，从github下载下来时可能解压有问题.因此这部分网速慢时最好手工做)'
VNPY_PKG_NAME='v2.0.3.tar.gz' 
wget -c https://github.com/vnpy/vnpy/archive/$VNPY_PKG_NAME

# ‘解压VNPY'
ls *.tar.gz | xargs -n1 tar -xzvf  

# ’conda'
wget -c https://repo.anaconda.com/archive/Anaconda3-2019.03-Linux-x86_64.sh

# ********** 2.安装anaconda（如果直接用系统的pip装，编译ta-lib会有问题) **********'
chmod 777 * 
bash ./*conda*.sh -b 		# ‘静默安装'
PATH="~/anaconda3/bin:$PATH"	# 这样脚本里才用得到conda
conda init 			#往bashrc里写配置
conda update conda -y
conda config --set auto_activate_base false #让conda初始化时不要默认进base环境

# ’创建环境'
conda create -n py37_quant python=3.7 -y 
activate py37_quant

# ‘********** 3.安装Linux依赖库 **********'
SUDO='sudo'
if [ $USER = 'root' ]
then
    SUDO=''
fi

# 'gcc要用gcc-7 --> https://gist.github.com/jlblancoc/99521194aba975286c80f93e47966dc5'
SUDO=
$SUDO apt-get install -y software-properties-common python-software-properties
$SUDO add-apt-repository ppa:ubuntu-toolchain-r/test
$SUDO apt update 
$SUDO apt install g++-7 -y
$SUDO update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 60 --slave /usr/bin/g++ g++ /usr/bin/g++-7
$SUDO update-alternatives --config gcc
ls -la /usr/bin/ | grep -oP "[\S]*(gcc|g\+\+)(-[a-z]+)*[\s]" | xargs $SUDO bash -c 'for link in ${@:1}; do ln -s -f "/usr/bin/${link}-${0}" "/usr/bin/${link}"; done' 7

apt install -y screen mongodb libboost-all-dev cmake git libsnappy-dev python-snappy build-essential gawk python3 python3-pip python3-dev libpython3-dev ubuntu-desktop python-psycopg2
  
apt --fix-broken install -y
apt autoremove -y


# ‘********** 4.安装Python依赖库 **********'
# ’补充安装vnpy安装时必须或后期需要，但install.sh中未包含的依赖项'
conda install -y libgfortran==1 matplotlib qtpy jupyter requests
yes | pip install psycopg2-binary


# ‘********** 5.安装VNPY **********'
cd vnpy* 
bash ./install.sh


# ’********** 6.补丁解决vnpy2.0.3缺ctp的.so的问题 **********'
cd vnpy/api/ctp
wget -c https://github.com/hlxstc/vnpy/raw/c9e22d3a2a2d1d047db133d7201f893483e05fc5/vnpy/api/ctp/vnctpmd.cpython-37m-x86_64-linux-gnu.so
wget -c https://github.com/hlxstc/vnpy/raw/c9e22d3a2a2d1d047db133d7201f893483e05fc5/vnpy/api/ctp/vnctptd.cpython-37m-x86_64-linux-gnu.so
mv vnpy/api/ctp/libthostmduserapi_se.so vnpy/api/ctp/libthostmduserapi.so 
mv vnpy/api/ctp/libthosttraderapi_se.so vnpy/api/ctp/libthosttraderapi.so

# ‘********** 7.放一个helloworld文件 **********'
echo '
from vnpy.event import EventEngine
from vnpy.trader.engine import MainEngine
from vnpy.trader.ui import MainWindow, create_qapp
from vnpy.gateway.ctp import CtpGateway
from vnpy.app.cta_strategy import CtaStrategyApp

def main():

    qapp = create_qapp()

    event_engine = EventEngine()
    main_engine = MainEngine(event_engine)
    
    main_engine.add_gateway(CtpGateway)
    main_engine.add_app(CtaStrategyApp)

    main_window = MainWindow(main_engine, event_engine)
    main_window.showMaximized()

    qapp.exec()

if __name__ == "__main__":
    main()
' > hello.py

# ********** 8.安装远程桌面 **********'
# teamviewer'
cd
wget -c https://download.teamviewer.com/download/linux/teamviewer_amd64.deb 
dpkg -i teamviewer*.deb 
apt autoremove -y 
apt --fix-broken install -y

# '重启让ECS的图形界面(ubuntu-desktop)生效，这样才能开teamviewer'
reboot

# '********** 9.测试GUI **********'
# '重启之后，通过图形桌面的ternminal运行下面命令，可以看到图形界面启动（第一次需要30秒)'
echo '
su
source activate py37_quant
cd ~/vnpy*
python hello.py
'



# ' ********** Appendix **********'
echo '
++++ Ta-lib的安装 +++
+ 不能用"conda install -y -c developer ta-lib"，这样的话会把python降级到3.5，与vnpy不兼容
+ vnpy的install.sh中会下载ta-lib的代码并编译，但在非root的用户下编译会出权限错误
+ 如果没有先下载源代码编译，直接用pip install ta-lib的话会报错找不到文件，原因是要用gcc-7



'


