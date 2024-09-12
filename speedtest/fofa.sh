#!/bin/bash
# cd /root/iptv
# read -p "确定要运行脚本吗？(y/n): " choice

# 判断用户的选择，如果不是"y"则退出脚本
# if [ "$choice" != "y" ]; then
#     echo "脚本已取消."
#     exit 0
# fi

time=$(date +%m%d%H%M)
i=0

if [ $# -eq 0 ]; then
  echo "请选择城市："
   echo "1. 广东电信（Guangdong_332）"
   echo "2. 广州移动（Guangdong_103）"
   echo "3. 深圳联通（Guangdong_145）"
   echo "4. 四川电信（Sichuan_333）"
    #echo "5. 湖南电信（Hunan_282）"
   echo "6. 北京联通（Beijing_liantong_145）"
  # echo "6. 江西（Jiangxi_105）"
  # echo "7. 江苏（Jiangsu）"
 
  # echo "9. 河南电信（Henan_327）"
  # echo "10. 山西电信（Shanxi_117）"
 #  echo "11. 天津联通（Tianjin_160）"
  # echo "12. 湖北电信（Hubei_90）"
  # echo "13. 福建电信（Fujian_114）"
   # echo "4. 浙江电信（Zhejiang_120）"
 #  echo "15. 河北联通（Hebei_313）"
 #  echo "16. 重庆电信（Chongqing_161）" 
  # echo "17. 陕西（Sanxi_123）"
  # echo "18. 广西（Guangxi_163）"
  # echo "19. 安徽（Anhui_191）"
  echo "0. 全部"
  read -t 10 -p "输入选择或在10秒内无输入将默认选择全部: " city_choice

  if [ -z "$city_choice" ]; then
      echo "未检测到输入，自动选择全部选项..."
      city_choice=0
  fi

else
  city_choice=$1
fi

# 根据用户选择设置城市和相应的stream
case $city_choice in
    1)
        city="Guangdong_332"
        stream="udp/239.77.1.98:5146"
        channel_key="广东电信"
        url_fofa=$(echo  '"udpxy" && country="CN" && region="Guangdong" && protocol="http"' | base64 |tr -d '\n')
        url_fofa="https://fofa.info/result?qbase64="$url_fofa
        ;;
    2)
        city="Guangdong_103"
        stream="udp/239.10.0.63:1025"
	channel_key="广东移动"
        url_fofa=$(echo  '"udpxy" && country="CN" && region="Guangdong" && port="8601"' | base64 |tr -d '\n')
        url_fofa="https://fofa.info/result?qbase64="$url_fofa
        ;;
    3)
        city="Guangdong_145"
        stream="rtp/239.20.0.64:3144"
        channel_key="广东联通"
        url_fofa=$(echo  '"udpxy" && country="CN" && region="Guangdong" && protocol="http" && org="China Mobile communications corporation"' | base64 |tr -d '\n')
        url_fofa="https://fofa.info/result?qbase64="$url_fofa
        ;;
    4)
        city="Sichuan_333"
        stream="udp/239.93.42.33:5140"
        channel_key="四川电信"
        url_fofa=$(echo  '"udpxy" && country="CN" && region="Sichuan" && org="CHINA UNICOM China169 Backbone"  && protocol="http"' | base64 |tr -d '\n')
        url_fofa=$(echo  '"udpxy" && country="CN" && region="Sichuan" && protocol="http"' | base64 |tr -d '\n')
        url_fofa="https://fofa.info/result?qbase64="$url_fofa
        ;;
   5)
        city="Hunan_282"
        stream="udp/239.76.252.35:9000"
        channel_key="湖南电信"
        url_fofa=$(echo  '"udpxy" && country="CN" && region="Hunan" && port="8888"' | base64 |tr -d '\n')
        url_fofa="https://fofa.info/result?qbase64="$url_fofa
        ;;
    6)
        city="Beijing_liantong_145"
        stream="rtp/239.3.1.236:2000"
        channel_key="北京联通"
        url_fofa=$(echo  '"udpxy" && country="CN" && region="Beijing" && org="China Unicom Beijing Province Network" && protocol="http"' | base64 |tr -d '\n')
        url_fofa="https://fofa.info/result?qbase64="$url_fofa
        ;;
    
    0)
        # 如果选择是“全部选项”，则逐个处理每个选项
        for option in {1..19}; do
          bash  "$0" $option  # 假定fofa.sh是当前脚本的文件名，$option将递归调用
        done
        exit 0
        ;;

    *)
        echo "错误：无效的选择。"
        exit 1
        ;;
esac



# 使用城市名作为默认文件名，格式为 CityName.ip
ipfile="ip/${city}.ip"
only_good_ip="ip/${city}.onlygood.ip"
rm -f $only_good_ip
# 搜索最新 IP
echo "===============从 fofa 检索 ip+端口================="
curl -o test.html "$url_fofa"
#echo $url_fofa
echo "$ipfile"
grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$' test.html | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' > "$ipfile"
rm -f test.html
# 遍历文件 A 中的每个 IP 地址
while IFS= read -r ip; do
    # 尝试连接 IP 地址和端口号，并将输出保存到变量中
    tmp_ip=$(echo -n "$ip" | sed 's/:/ /')
    echo "nc -w 1 -v -z $tmp_ip 2>&1"
    output=$(nc -w 1 -v -z $tmp_ip 2>&1)
    echo $output    
    # 如果连接成功，且输出包含 "succeeded"，则将结果保存到输出文件中
    if [[ $output == *"succeeded"* ]]; then
        # 使用 awk 提取 IP 地址和端口号对应的字符串，并保存到输出文件中
        echo "$output" | grep "succeeded" | awk -v ip="$ip" '{print ip}' >> "$only_good_ip"
    fi
done < "$ipfile"

echo "===============检索完成================="

# 检查文件是否存在
if [ ! -f "$only_good_ip" ]; then
    echo "错误：文件 $only_good_ip 不存在。"
    exit 1
fi

lines=$(wc -l < "$only_good_ip")
echo "【$only_good_ip】内 ip 共计 $lines 个"

i=0
time=$(date +%Y%m%d%H%M%S) # 定义 time 变量
while IFS= read -r line; do
    i=$((i + 1))
    ip="$line"
    url="http://$ip/$stream"
    echo "$url"
    curl "$url" --connect-timeout 3 --max-time 10 -o /dev/null >zubo.tmp 2>&1
    a=$(head -n 3 zubo.tmp | awk '{print $NF}' | tail -n 1)

    echo "第 $i/$lines 个：$ip $a"
    echo "$ip $a" >> "speedtest_${city}_$time.log"
done < "$only_good_ip"

rm -f zubo.tmp
awk '/M|k/{print $2"  "$1}' "speedtest_${city}_$time.log" | sort -n -r >"result_fofa_${city}.txt"
cat "result_fofa_${city}.txt"
ip1=$(awk 'NR==1{print $2}' result_fofa_${city}.txt)
ip2=$(awk 'NR==2{print $2}' result_fofa_${city}.txt)
ip3=$(awk 'NR==3{print $2}' result_fofa_${city}.txt)
rm -f "speedtest_${city}_$time.log"

# 用 3 个最快 ip 生成对应城市的 txt 文件
program="template/template_${city}.txt"

sed "s/ipipip/$ip1/g" "$program" > tmp1.txt
sed "s/ipipip/$ip2/g" "$program" > tmp2.txt
sed "s/ipipip/$ip3/g" "$program" > tmp3.txt
cat tmp1.txt tmp2.txt tmp3.txt > "txt/fofa_${city}.txt"

rm -rf tmp1.txt tmp2.txt tmp3.txt

rm -rf zubo_fofa.txt
#--------------------合并所有城市的txt文件为:   zubo_fofa.txt-----------------------------------------
echo "📡  广东频道,#genre#" >>zubo_fofa.txt
cat txt/fofa_Guangdong_332.txt >>zubo_fofa.txt
echo "📡  广州频道,#genre#" >>zubo_fofa.txt
cat txt/fofa_Guangdong_103.txt >>zubo_fofa.txt
echo "📡  深圳频道,#genre#" >>zubo_fofa.txt
cat txt/fofa_Guangdong_145.txt >>zubo_fofa.txt
echo "📡  四川频道,#genre#" >>zubo_fofa.txt
cat txt/fofa_Sichuan_333.txt >>zubo_fofa.txt
echo "📡  湖南频道,#genre#" >>zubo_fofa.txt
cat txt/fofa_Hunan_282.txt >>zubo_fofa.txt
echo "📡  北京联通,#genre#" >>zubo_fofa.txt
cat txt/fofa_Beijing_liantong_145.txt >>zubo_fofa.txt

for a in result/*.txt; do echo "";echo "========================= $(basename "$a") ==================================="; cat $a; done
