# 이벤트로그를 사용하여 특정 회수 이상 로그인 실패 아이피에 대하여 
# MY BLACKLIST 방화벽 등록
# 2014.05.22 NDH
# version 1.1


###################### Config ###################### 
 $regex1 = [regex] "로그온 유형:";
 $regex2 = [regex] "원본 네트워크 주소:\t(\d+\.\d+\.\d+\.\d+)";
 $MyIp = "222.122.20.*";
 $deny_count = 5;
 $deny_rule_name = "MY BLACKLIST"
###################### Config ###################### 

$fw=New-object -comObject HNetCfg.FwPolicy2; # http://blogs.technet.com/b/jamesone/archive/2009/02/18/how-to-manage-the-windows-firewall-settings-with-powershell.aspx 
$RuleCHK=$fw.rules | where-object {$_.name –eq $deny_rule_name}
if(!$RuleCHK){ $deny_rule_name + " 룰이 생성되어 있지 않습니다."; exit; }


$blacklist = @();
$list ="";


 "-----------------------------"
 "RDP 공격 차단 : " + (get-date); 
 "-----------------------------"


$ips = get-eventlog Security  | Where-Object {$_.EventID -eq 4625 } | foreach {
$m = $regex2.Match($_.Message); $ip = $m.Groups[1].Value; $ip; } | Sort-Object | Tee-Object -Variable list | Get-Unique 

if($list.length -ge 0) {
    foreach ( $attack_ip in $list) 
    {
        if($attack_ip){
            $myrule = $fw.Rules | where {$_.Name -eq $deny_rule_name} | select -First 1; # Potential bug here? 
       
            if (-not ($blacklist -contains $attack_ip)) 
             {
                $attack_count = ($list | Select-String $attack_ip -SimpleMatch | Measure-Object).count; 
                if ($attack_count -ge $deny_count) {
                        if (-not ($myrule.RemoteAddresses -match $attack_ip) -and -not ($attack_ip -like  $MyIp)) 
                         {
                            "Found RDP attacking IP on 3389: " + $attack_ip + ", with count: " + $attack_count;                      
                            $blacklist = $blacklist + $attack_ip;
                            "Adding this IP into firewall blocklist: " + $attack_ip;  
                            $myrule.RemoteAddresses+=(","+$attack_ip); 
                            #echo $attack_ip >>  C:\BlackListIP.txt
                            
                         } else {
                             $attack_ip + " : 이미 등록된 IP"
                         }
                   }
             }
          }

    }
}else{
    "인증 실패 이벤트 로그가 없습니다."
}

 "-----------------------------"
 ".........실행 완료..........." 
 "-----------------------------"